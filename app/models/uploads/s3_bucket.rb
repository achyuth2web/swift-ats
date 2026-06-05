module Uploads
  class S3Bucket
    DEFAULT_EXPIRY_TIME = 600

    def initialize
      aws_options = {
        region: ENV['AWS_REGION_NAME'],
        access_key_id: ENV['AWS_ACCESS_KEY_ID'],
        secret_access_key: ENV['AWS_SECRET_KEY_ID']
      }

      @s3 = Aws::S3::Client.new(aws_options)

      @signer = Aws::S3::Presigner.new(client: @s3)
      @bucket_name = ENV['AWS_S3_BUCKET']
      @s3_resource = Aws::S3::Resource.new(client: @s3)
    end

    #
    # generate_presigned_url
    # @param {String} file_path
    # @param {Integer} expires_in
    # @param {Symbol} content_disposition
    #
    # Generates a presigned URL for a specific object in the S3 bucket
    #
    def generate_presigned_url(file_path, expires_in = DEFAULT_EXPIRY_TIME, content_disposition = :inline)
      return false unless file_exists?(file_path)

      @signer.presigned_url(
        :get_object,
        bucket: @bucket_name,
        key: file_path,
        expires_in: expires_in,
        response_content_disposition: content_disposition
      )
    rescue Aws::S3::Errors::ServiceError => e
      Rollbar.error(e, "Error generating presigned URL for '#{file_path}': #{e.message}")
      raise e
    end    

    #
    # file_exists?
    # @param {String} file_key
    #
    # Checks if a file exists in the S3 bucket
    #
    def file_exists?(file_key)
      object = @s3_resource.bucket(@bucket_name).object(file_key)
      object.exists?
    rescue Aws::S3::Errors::ServiceError => e
      Rollbar.error(e, "Error checking file existence for '#{file_key}' in bucket '#{@bucket_name}': #{e.message}")
      false
    end

    #
    # get_s3_object
    # @param {String} file_path
    #
    # Checks if a file exists in the S3 bucket and return s3 object.
    #
    def get_s3_object(file_path)
      object = @s3_resource.bucket(@bucket_name).object(file_path)
      object if object.exists?
    rescue Aws::S3::Errors::ServiceError => e
      Rollbar.error(e, "Error checking file existence for '#{file_path}' in bucket '#{@bucket_name}': #{e.message}")
      false
    end

    #
    # update_file
    # @param {String} file_key
    # @param {IO} file_body
    # @param {String} content_type
    # @param {Symbol} content_disposition
    #
    # Uploads a file to the S3 bucket
    #
    def update_file(file_key, file_body, content_type, content_disposition = :inline)
      response = @s3.put_object({
        body: file_body,
        bucket: @bucket_name,
        key: file_key,
        content_type: content_type,
        content_disposition: content_disposition
      })
      if response.etag.present?
        "https://#{@bucket_name}.s3.#{ENV['AWS_REGION_NAME']}.amazonaws.com/#{file_key}"
      else
        false
      end
    rescue Aws::S3::Errors::ServiceError => e
      Rollbar.error(e, "Error updating file '#{file_key}': #{e.message}")
      false
    end

    #
    # copy_object
    # @param {String} source_key
    # @param {String} target_key
    #
    # Copies an object from the source key to the target key in the S3 bucket
    #
    def copy_object(source_key, target_key)
      source_object = @s3_resource.bucket(@bucket_name).object(source_key)
      source_object.copy_to(bucket: @bucket_name, key: target_key)
    rescue Aws::S3::Errors::ServiceError => e
      Rollbar.error(e, "Error copying object from '#{source_key}' to '#{target_key}': #{e.message}")
      raise e
    end

    #
    # list_objects
    # @param {String} folder_path
    #
    # Lists all objects in the specified folder path
    #
    def list_objects(folder_path)
      @s3_resource.bucket(@bucket_name).objects(prefix: folder_path).collect(&:key)
    rescue Aws::S3::Errors::ServiceError => e
      Rollbar.error(e, "Error listing objects in folder '#{folder_path}': #{e.message}")
      raise e
    end

    #
    # generate_multi_presigned_url
    # @param {Array} object_keys
    #
    # Generates presigned URLs for multiple objects
    #
    def generate_multi_presigned_url(object_keys)
      object_keys.map { |key| generate_presigned_url(key) }
    rescue Aws::S3::Errors::ServiceError => e
      Rollbar.error(e, "Error generating presigned URLs for objects: #{e.message}")
      raise e
    end

    def delete_file(file_path)
      @s3_resource.bucket(@bucket_name).object(file_path).delete
    rescue Aws::S3::Errors::ServiceError => e
      Rollbar.error(e, "Error deleting file '#{file_path}': #{e.message}")
      raise e
    end
  end
end
