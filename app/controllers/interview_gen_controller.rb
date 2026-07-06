class InterviewGenController < ApplicationController
  LEVELS = %w[Junior Mid Senior Lead].freeze

  QUESTIONS = {
  # Languages
  "Ruby" => {
    "Junior" => [
      "What is the difference between a symbol and a string in Ruby?",
      "What is the difference between `nil` and `false`?",
      "How do you define a class and create an instance in Ruby?",
      "What is an array and a hash, and how do you iterate over each?"
    ],
    "Mid" => [
      "Explain blocks, procs, and lambdas and when you'd use each",
      "What are Ruby modules and mixins used for?",
      "How do you handle exceptions with begin/rescue/ensure?",
      "What is duck typing and how does Ruby use it?"
    ],
    "Senior" => [
      "How does Ruby's garbage collector and memory management work?",
      "Explain metaprogramming techniques like method_missing and define_method",
      "How would you profile and optimize a slow Ruby application?",
      "Explain the Ruby object model and method lookup path"
    ],
    "Lead" => [
      "How do you set and enforce Ruby coding standards across a team?",
      "How do you decide when to upgrade Ruby versions or adopt a new gem?",
      "How do you mentor engineers who are new to idiomatic Ruby?",
      "How do you balance refactoring legacy Ruby code against new feature work?"
    ]
  },

  "Python" => {
    "Junior" => [
      "What is the difference between a list and a tuple?",
      "What are Python's basic data types?",
      "How do you handle exceptions with try/except?",
      "What is the difference between `is` and `==`?"
    ],
    "Mid" => [
      "Explain Python decorators and give an example use case",
      "What are generators and how do they differ from regular functions?",
      "How do you manage dependencies with virtualenv/pip?",
      "What are list comprehensions and when would you use them?"
    ],
    "Senior" => [
      "How does the Global Interpreter Lock (GIL) affect concurrency?",
      "How would you optimize a CPU-bound vs I/O-bound Python application?",
      "Explain Python's memory management and garbage collection",
      "How do you design a Python package for reuse across multiple services?"
    ],
    "Lead" => [
      "How do you decide between multiprocessing, threading, and async in a team's codebase?",
      "How do you enforce code quality (linting, typing) across a Python team?",
      "How do you evaluate a new Python framework before adopting it?",
      "How do you mentor engineers moving from scripting to production-grade Python?"
    ]
  },

  "Java" => {
    "Junior" => [
      "What are the four main OOP principles?",
      "What is the difference between an interface and an abstract class?",
      "What is the difference between `==` and `.equals()`?",
      "What are the primitive data types in Java?"
    ],
    "Mid" => [
      "Explain the Java Collections Framework and when to use List vs Set vs Map",
      "How does exception handling work with checked vs unchecked exceptions?",
      "What is the purpose of the `static` keyword?",
      "How do you use generics in Java?"
    ],
    "Senior" => [
      "Explain JVM architecture and how the classloader works",
      "How does garbage collection work and how would you tune it?",
      "How do you diagnose and fix a memory leak in a Java application?",
      "Explain multithreading and concurrency utilities in java.util.concurrent"
    ],
    "Lead" => [
      "How do you evaluate whether to upgrade a major JDK version across services?",
      "How do you set architectural standards for a multi-team Java codebase?",
      "How do you mentor engineers on JVM performance tuning?",
      "How do you decide between monolith and microservices for a Java system?"
    ]
  },

  # Frontend
  "React" => {
    "Junior" => [
      "What is JSX and how does it work?",
      "What is the difference between props and state?",
      "What is a component and how do you create one?",
      "How do you render a list of items in React?"
    ],
    "Mid" => [
      "How do hooks like useState and useEffect work?",
      "What is the Context API and when would you use it?",
      "How do you handle forms and controlled components?",
      "How do you fetch data from an API in a React component?"
    ],
    "Senior" => [
      "Explain how the Virtual DOM and reconciliation work",
      "How do you optimize a React application's performance (memoization, code-splitting)?",
      "How would you design state management for a large-scale app?",
      "How do you handle server-side rendering or hydration issues?"
    ],
    "Lead" => [
      "How do you set frontend architecture standards across multiple teams?",
      "How do you evaluate a new state management or framework choice for the team?",
      "How do you mentor engineers on component design and reusability?",
      "How do you balance technical debt in a large, long-lived React codebase?"
    ]
  },

  "Angular" => {
    "Junior" => [
      "What is a component and a module in Angular?",
      "What is data binding and what types does Angular support?",
      "What is the purpose of a service in Angular?",
      "How do you create and use a basic directive?"
    ],
    "Mid" => [
      "Explain Angular lifecycle hooks and when you'd use them",
      "How does dependency injection work in Angular?",
      "How do you handle forms with reactive forms vs template-driven forms?",
      "How do you make HTTP calls using HttpClient?"
    ],
    "Senior" => [
      "How does Angular's change detection work and how would you optimize it?",
      "How do you structure a large Angular application with lazy-loaded modules?",
      "How would you diagnose and fix performance issues in an Angular app?",
      "Explain RxJS observables and how they're used in Angular"
    ],
    "Lead" => [
      "How do you set architectural standards for a multi-team Angular codebase?",
      "How do you evaluate migrating between major Angular versions?",
      "How do you mentor engineers on RxJS and reactive patterns?",
      "How do you balance shared component libraries across teams?"
    ]
  },

  "Vue" => {
    "Junior" => [
      "What is a Vue component and how do you create one?",
      "What is the difference between props and data?",
      "How do you bind data to the DOM with v-bind and v-model?",
      "What are Vue directives like v-if and v-for?"
    ],
    "Mid" => [
      "Explain Vue reactivity and how the reactivity system tracks changes",
      "Vue Composition API vs Options API — when would you use each?",
      "How do Vue components communicate with each other?",
      "How do you manage state with Vuex or Pinia?"
    ],
    "Senior" => [
      "How would you optimize rendering performance in a large Vue application?",
      "How do you structure a large-scale Vue app with modular components?",
      "How does Vue's virtual DOM diffing work under the hood?",
      "How would you handle server-side rendering with Nuxt?"
    ],
    "Lead" => [
      "How do you decide when to migrate from Vue 2 to Vue 3?",
      "How do you set frontend standards across multiple Vue teams?",
      "How do you mentor engineers on Composition API adoption?",
      "How do you evaluate build tooling choices for the team?"
    ]
  },

  # Backend
  "Ruby on Rails" => {
    "Junior" => [
      "What is the MVC architecture in Rails?",
      "What is the purpose of routes.rb?",
      "How do you create a basic model, view, and controller?",
      "What is a migration and how do you run one?"
    ],
    "Mid" => [
      "What are ActiveRecord associations (has_many, belongs_to, etc.)?",
      "How does Rails routing work, including nested routes?",
      "How do you use validations and callbacks in ActiveRecord models?",
      "How do you write and organize tests in a Rails app?"
    ],
    "Senior" => [
      "How do background jobs work in Rails and when would you use them?",
      "How would you diagnose and fix N+1 queries in a Rails app?",
      "How do you scale a Rails application (caching, read replicas)?",
      "How would you design a multi-tenant Rails application?"
    ],
    "Lead" => [
      "How do you decide when to extract a service from a Rails monolith?",
      "How do you plan a major Rails version upgrade across a codebase?",
      "How do you mentor engineers on Rails conventions and idioms?",
      "How do you balance technical debt in a long-lived Rails codebase?"
    ]
  },

  "Node.js" => {
    "Junior" => [
      "What is Node.js and how does it differ from browser JavaScript?",
      "What is npm and how do you manage dependencies?",
      "How do you create a basic HTTP server in Node.js?",
      "What is a callback function?"
    ],
    "Mid" => [
      "Explain how the Event Loop works in Node.js",
      "How does Express middleware work?",
      "How do you handle asynchronous operations (promises, async/await)?",
      "What are streams and when would you use them?"
    ],
    "Senior" => [
      "How would you scale a Node.js application across multiple cores/processes?",
      "How do you diagnose and fix a memory leak in a Node.js app?",
      "How would you design error handling and logging for a production service?",
      "How do you handle backpressure when working with streams?"
    ],
    "Lead" => [
      "How do you decide between a monolithic Node.js service and microservices?",
      "How do you set standards for error handling and observability across teams?",
      "How do you mentor engineers on async patterns and avoiding callback hell?",
      "How do you evaluate adopting a new Node.js runtime feature or major version?"
    ]
  },

  "Spring Boot" => {
    "Junior" => [
      "What is Spring Boot and how does it simplify Spring applications?",
      "What is the purpose of the @RestController annotation?",
      "What is application.properties/application.yml used for?",
      "How do you create a basic REST endpoint?"
    ],
    "Mid" => [
      "How does dependency injection work in Spring?",
      "What is Spring Boot auto-configuration and how does it work?",
      "How do REST controllers handle request/response serialization?",
      "How do you use Spring Data JPA repositories?"
    ],
    "Senior" => [
      "How do you secure a Spring Boot API (Spring Security, OAuth2/JWT)?",
      "How would you design a Spring Boot application for horizontal scaling?",
      "How do you handle distributed transactions or eventual consistency?",
      "How would you diagnose performance issues in a Spring Boot application?"
    ],
    "Lead" => [
      "How do you decide on service boundaries for Spring Boot microservices?",
      "How do you set standards for API versioning and security across teams?",
      "How do you mentor engineers on Spring's dependency injection patterns?",
      "How do you evaluate migrating between major Spring Boot versions?"
    ]
  },

  # Databases
  "SQL" => {
    "Junior" => [
      "What is the difference between a primary key and a foreign key?",
      "What is the difference between WHERE and HAVING?",
      "How do you write a basic SELECT query with filtering and sorting?",
      "What is a NULL value and how does it behave in comparisons?"
    ],
    "Mid" => [
      "Explain the different JOIN types (INNER, LEFT, RIGHT, FULL)",
      "What is normalization and why is it important?",
      "How do you write aggregate queries with GROUP BY and HAVING?",
      "What is a subquery vs a CTE (WITH clause)?"
    ],
    "Senior" => [
      "How do indexes work and how do you decide what to index?",
      "What are the ACID properties and why do they matter?",
      "How would you diagnose and optimize a slow query using an execution plan?",
      "How do you handle transactions and isolation levels?"
    ],
    "Lead" => [
      "How do you set standards for schema design and migrations across teams?",
      "How do you decide when to denormalize for performance?",
      "How do you mentor engineers on writing efficient queries?",
      "How do you plan a large-scale schema migration with minimal downtime?"
    ]
  },

  "PostgreSQL" => {
    "Junior" => [
      "What is the difference between PostgreSQL and other relational databases?",
      "What are basic data types available in PostgreSQL?",
      "How do you create a table and insert data?",
      "What is a foreign key constraint?"
    ],
    "Mid" => [
      "What indexing strategies does PostgreSQL support (B-tree, GIN, GiST)?",
      "What are materialized views and when would you use them?",
      "How do you use JSONB columns in PostgreSQL?",
      "How do you write and use a stored procedure or function?"
    ],
    "Senior" => [
      "How does MVCC (Multi-Version Concurrency Control) work in PostgreSQL?",
      "Partitioning vs sharding — when would you use each?",
      "How would you diagnose and fix table/index bloat?",
      "How do you tune PostgreSQL for high write throughput?"
    ],
    "Lead" => [
      "How do you plan a PostgreSQL version upgrade with minimal downtime?",
      "How do you decide between vertical scaling, read replicas, and sharding?",
      "How do you set standards for migrations and schema review across teams?",
      "How do you mentor engineers on query optimization and indexing strategy?"
    ]
  },

  "MongoDB" => {
    "Junior" => [
      "What is a document database and how does it differ from relational databases?",
      "What is a collection and a document in MongoDB?",
      "How do you perform basic CRUD operations in MongoDB?",
      "What is the _id field used for?"
    ],
    "Mid" => [
      "Embedded vs referenced documents — when would you use each?",
      "How does indexing work in MongoDB?",
      "What are aggregation pipelines and how do you use them?",
      "How do you model one-to-many relationships in MongoDB?"
    ],
    "Senior" => [
      "How does MongoDB handle sharding and replica sets?",
      "How would you diagnose and optimize a slow aggregation pipeline?",
      "How do you design a schema for a high-write-throughput application?",
      "How does MongoDB handle consistency and write concerns?"
    ],
    "Lead" => [
      "How do you decide between MongoDB and a relational database for a new project?",
      "How do you plan a large-scale MongoDB migration or resharding?",
      "How do you set standards for schema design across teams using MongoDB?",
      "How do you mentor engineers on aggregation pipeline performance?"
    ]
  },

  # Cloud
  "AWS" => {
    "Junior" => [
      "What is IAM and why is it important?",
      "What is the difference between EC2 and S3?",
      "What is a VPC?",
      "What is the difference between a public and private subnet?"
    ],
    "Mid" => [
      "EC2 vs Lambda — when would you use each?",
      "How do you secure cloud resources (IAM policies, security groups)?",
      "How do you use S3 lifecycle policies and static hosting?",
      "What is the difference between RDS and DynamoDB?"
    ],
    "Senior" => [
      "How would you design a highly available, multi-AZ architecture on AWS?",
      "How do you use auto-scaling and load balancing to handle variable traffic?",
      "How would you diagnose and reduce AWS cost across a large deployment?",
      "How do you design a disaster recovery strategy across regions?"
    ],
    "Lead" => [
      "How do you set cloud governance and cost-control standards across teams?",
      "How do you decide between serverless and container-based architectures?",
      "How do you mentor engineers on IAM least-privilege practices?",
      "How do you plan a large-scale cloud migration project?"
    ]
  },

  "Azure" => {
    "Junior" => [
      "What are Azure Resource Groups used for?",
      "What is the difference between a VM and an Azure Function?",
      "What is Azure Active Directory (Azure AD) used for?",
      "What are the basic Azure Storage options (Blob, Table, Queue)?"
    ],
    "Mid" => [
      "What are Azure Functions and when would you use them?",
      "How does Azure AD handle authentication and authorization?",
      "How do you deploy and manage resources with ARM templates or Bicep?",
      "How do you choose the right Azure Storage option for a workload?"
    ],
    "Senior" => [
      "How would you design a highly available architecture using availability zones?",
      "How do you secure an Azure environment (RBAC, NSGs, Key Vault)?",
      "How would you diagnose and optimize Azure costs across subscriptions?",
      "How do you design a CI/CD pipeline using Azure DevOps?"
    ],
    "Lead" => [
      "How do you set governance standards across multiple Azure subscriptions?",
      "How do you decide between Azure-native services and third-party alternatives?",
      "How do you mentor engineers on Azure security best practices?",
      "How do you plan a large-scale migration to Azure?"
    ]
  },

  "GCP" => {
    "Junior" => [
      "What is Google Cloud IAM?",
      "What is the difference between a VM and Cloud Run?",
      "What is a GCP project and how does billing work?",
      "What are basic GCP storage options?"
    ],
    "Mid" => [
      "Cloud Run vs GKE — when would you use each?",
      "What are common BigQuery use cases?",
      "How does GCP networking work (VPCs, subnets, firewall rules)?",
      "How do you deploy a service using Cloud Build and Cloud Run?"
    ],
    "Senior" => [
      "How would you design a highly available, multi-region architecture on GCP?",
      "How do you optimize BigQuery query performance and cost?",
      "How would you diagnose and reduce GCP infrastructure costs?",
      "How do you design a data pipeline using Pub/Sub and Dataflow?"
    ],
    "Lead" => [
      "How do you set governance standards across multiple GCP projects?",
      "How do you decide between GKE, Cloud Run, and Cloud Functions for a new service?",
      "How do you mentor engineers on GCP IAM best practices?",
      "How do you plan a large-scale migration to GCP?"
    ]
  },

  # DevOps
  "Docker" => {
    "Junior" => [
      "What is containerization and how does it differ from virtual machines?",
      "What is a Dockerfile and what does it contain?",
      "How do you build and run a basic Docker image?",
      "What is the difference between an image and a container?"
    ],
    "Mid" => [
      "Explain Docker layers and how caching works during builds",
      "What is Docker Compose and when would you use it?",
      "How are volumes used to persist data?",
      "How do you manage environment variables and secrets in Docker?"
    ],
    "Senior" => [
      "How would you optimize a Docker image for size and build speed?",
      "How do you design multi-stage builds for production images?",
      "How would you diagnose a container that's crashing or leaking memory?",
      "How do you handle networking between multiple containers in production?"
    ],
    "Lead" => [
      "How do you set standards for Dockerfile quality and image security scanning?",
      "How do you decide when to move from Docker Compose to an orchestrator?",
      "How do you mentor engineers on writing efficient, secure Dockerfiles?",
      "How do you plan a containerization strategy for a legacy application?"
    ]
  },

  "Kubernetes" => {
    "Junior" => [
      "What is a Pod in Kubernetes?",
      "What is the difference between a Deployment and a Pod?",
      "What is a Service used for?",
      "What is a namespace and why would you use one?"
    ],
    "Mid" => [
      "Deployment vs StatefulSet — when would you use each?",
      "Explain Services and Ingress and how traffic is routed",
      "How do ConfigMaps and Secrets work?",
      "How do you perform a rolling update or rollback?"
    ],
    "Senior" => [
      "How would you design autoscaling (HPA/VPA) for a production workload?",
      "How do you diagnose and fix a pod that's stuck in CrashLoopBackOff?",
      "How would you design multi-cluster or multi-region Kubernetes architecture?",
      "How do you secure a Kubernetes cluster (RBAC, network policies)?"
    ],
    "Lead" => [
      "How do you set standards for resource requests/limits and cluster governance?",
      "How do you decide between managed Kubernetes and self-hosted?",
      "How do you mentor engineers on Kubernetes troubleshooting?",
      "How do you plan a migration from a legacy platform to Kubernetes?"
    ]
  },

  "Terraform" => {
    "Junior" => [
      "What is Infrastructure as Code and why is it useful?",
      "What is a Terraform provider?",
      "How do you write a basic Terraform resource block?",
      "What does terraform plan and terraform apply do?"
    ],
    "Mid" => [
      "Explain Terraform state and why it matters",
      "Modules vs Workspaces — when would you use each?",
      "How do you manage secrets in Terraform?",
      "How do you structure a Terraform project for multiple environments?"
    ],
    "Senior" => [
      "How would you design remote state management and locking for a team?",
      "How do you handle drift detection and reconciliation?",
      "How would you refactor a monolithic Terraform codebase into reusable modules?",
      "How do you manage Terraform state across multiple cloud accounts/regions?"
    ],
    "Lead" => [
      "How do you set standards for module reuse and review across teams?",
      "How do you decide between Terraform and other IaC tools?",
      "How do you mentor engineers on writing safe, reviewable Terraform changes?",
      "How do you plan a large-scale infrastructure migration using Terraform?"
    ]
  },

  # AI / ML
  "Machine Learning" => {
    "Junior" => [
      "What is the difference between supervised and unsupervised learning?",
      "What is a training set vs a test set?",
      "What is overfitting?",
      "What is a basic evaluation metric like accuracy?"
    ],
    "Mid" => [
      "Explain cross-validation and why it's used",
      "How do you evaluate models beyond accuracy (precision, recall, F1)?",
      "How do you handle imbalanced datasets?",
      "What is feature engineering and why does it matter?"
    ],
    "Senior" => [
      "How would you design a model deployment and monitoring pipeline in production?",
      "How do you detect and handle model drift over time?",
      "How would you choose between a simpler model and a more complex one?",
      "How do you scale training on large datasets?"
    ],
    "Lead" => [
      "How do you set standards for model evaluation and validation across a team?",
      "How do you decide when a problem needs ML versus simpler heuristics?",
      "How do you mentor data scientists on production ML best practices?",
      "How do you manage ethical/bias considerations in ML systems your team ships?"
    ]
  },

  "TensorFlow" => {
    "Junior" => [
      "What is TensorFlow used for?",
      "What are tensors?",
      "What is the difference between TensorFlow and Keras?",
      "How do you build a basic neural network layer?"
    ],
    "Mid" => [
      "How do neural networks train (forward pass, backpropagation)?",
      "How do you prevent overfitting (dropout, regularization)?",
      "How do you use TensorFlow Datasets for data pipelines?",
      "What is a loss function and how do you choose one?"
    ],
    "Senior" => [
      "Explain TensorFlow's architecture (graphs, eager execution, autodiff)",
      "How would you optimize training performance (batching, mixed precision)?",
      "How do you deploy a TensorFlow model to production (TF Serving, TFLite)?",
      "How do you debug a model that isn't converging?"
    ],
    "Lead" => [
      "How do you decide between TensorFlow and other frameworks for a new project?",
      "How do you set standards for model versioning and reproducibility?",
      "How do you mentor engineers on debugging deep learning training issues?",
      "How do you plan compute/infrastructure needs for large-scale model training?"
    ]
  },

  "LangChain" => {
    "Junior" => [
      "What are chains in LangChain?",
      "What is a prompt template?",
      "What is retrieval augmented generation (RAG) at a high level?",
      "What is an LLM and how does LangChain interact with it?"
    ],
    "Mid" => [
      "Explain retrieval augmented generation and how you'd implement it",
      "How do you manage prompt templates and reuse them?",
      "How do you use memory to maintain context across a conversation?",
      "How do you connect LangChain to a vector store?"
    ],
    "Senior" => [
      "How do agents work in LangChain and how do you constrain their actions safely?",
      "How would you design a RAG pipeline for production scale and latency?",
      "How do you evaluate and reduce hallucinations in an LLM application?",
      "How do you handle cost and token usage optimization at scale?"
    ],
    "Lead" => [
      "How do you set standards for prompt review and safety across a team?",
      "How do you decide between building custom agent logic vs using existing frameworks?",
      "How do you mentor engineers new to LLM application development?",
      "How do you evaluate the ROI and risk of an LLM-based feature before shipping it?"
    ]
  },

  # BI
  "Power BI" => {
    "Junior" => [
      "What is DAX used for?",
      "How do you import data into Power BI?",
      "What is a basic visualization you can create in Power BI?",
      "What is a report vs a dashboard in Power BI?"
    ],
    "Mid" => [
      "What are relationships and how do you define them between tables?",
      "Import vs DirectQuery — what are the trade-offs?",
      "How do you write a calculated column vs a measure in DAX?",
      "How do you use filters and slicers effectively?"
    ],
    "Senior" => [
      "How do you optimize dashboards for performance with large datasets?",
      "How would you design a data model for a complex multi-table report?",
      "How do you handle row-level security in Power BI?",
      "How do you troubleshoot slow DAX measures?"
    ],
    "Lead" => [
      "How do you set standards for data governance across Power BI reports?",
      "How do you decide between Power BI and other BI tools for a new use case?",
      "How do you mentor analysts on DAX and data modeling best practices?",
      "How do you manage a Power BI rollout across multiple business units?"
    ]
  },

  "Tableau" => {
    "Junior" => [
      "How do Tableau extracts work?",
      "What is a dimension vs a measure in Tableau?",
      "How do you create a basic chart in Tableau?",
      "What is a worksheet vs a dashboard?"
    ],
    "Mid" => [
      "Explain calculated fields and give an example",
      "What are parameters and how are they used?",
      "How do you connect Tableau to a live data source vs an extract?",
      "How do you use filters and actions to build interactivity?"
    ],
    "Senior" => [
      "How do you optimize dashboards for performance with large datasets?",
      "How would you design a data model across multiple joined/blended sources?",
      "How do you handle row-level security in Tableau?",
      "How do you troubleshoot a slow-loading dashboard?"
    ],
    "Lead" => [
      "How do you set governance standards for Tableau reports across teams?",
      "How do you decide between Tableau and other BI tools?",
      "How do you mentor analysts on dashboard design best practices?",
      "How do you manage a Tableau rollout across multiple business units?"
    ]
  },

  # Testing
  "RSpec" => {
    "Junior" => [
      "Describe RSpec structure (describe, context, it)",
      "What is an expectation/matcher in RSpec?",
      "How do you run a single RSpec test file?",
      "What is a before block used for?"
    ],
    "Mid" => [
      "What are shared examples and when would you use them?",
      "Mocking vs stubbing — what's the difference?",
      "How do you test Rails controllers with RSpec?",
      "How do you use factories (FactoryBot) effectively in tests?"
    ],
    "Senior" => [
      "How would you design a test suite to minimize flaky tests?",
      "How do you optimize a slow-running test suite?",
      "How do you test asynchronous code (background jobs) with RSpec?",
      "How do you structure request/system specs vs unit specs?"
    ],
    "Lead" => [
      "How do you set testing standards and coverage expectations across a team?",
      "How do you decide what to unit test vs integration test?",
      "How do you mentor engineers on writing maintainable specs?",
      "How do you handle a legacy codebase with poor test coverage?"
    ]
  },

  "Selenium" => {
    "Junior" => [
      "What is Selenium WebDriver?",
      "How do you locate elements on a page (id, class, xpath)?",
      "How do you write a basic test that clicks a button and checks a result?",
      "What is the difference between Selenium and a headless browser?"
    ],
    "Mid" => [
      "How do you handle waits (implicit vs explicit) in Selenium?",
      "What is the Page Object Model and why use it?",
      "How do you handle dynamic elements or pop-ups?",
      "How do you integrate Selenium tests into a CI pipeline?"
    ],
    "Senior" => [
      "How do you automate cross-browser testing at scale?",
      "How would you reduce flakiness in a large Selenium test suite?",
      "How do you design a test framework that scales across multiple applications?",
      "How do you handle parallel test execution?"
    ],
    "Lead" => [
      "How do you set standards for test automation coverage across teams?",
      "How do you decide between Selenium and other tools (Cypress, Playwright)?",
      "How do you mentor QA engineers on writing maintainable automation?",
      "How do you balance manual vs automated testing strategy for a release?"
    ]
  },

  # Project Management
  "Agile" => {
    "Junior" => [
      "What are the core Agile principles?",
      "What is a sprint?",
      "What is a daily standup used for?",
      "What is the difference between a user story and a task?"
    ],
    "Mid" => [
      "Scrum vs Kanban — what are the key differences?",
      "What is sprint planning and how do you participate in it?",
      "How do you estimate stories (story points, planning poker)?",
      "What is a retrospective and how do you make it effective?"
    ],
    "Senior" => [
      "How do you scale Agile practices across multiple teams (SAFe, LeSS)?",
      "How do you handle scope creep within a sprint?",
      "How do you balance technical debt against feature delivery in planning?",
      "How do you measure team velocity and use it responsibly?"
    ],
    "Lead" => [
      "How do you coach teams that are struggling to adopt Agile practices?",
      "How do you align Agile delivery with broader business/roadmap goals?",
      "How do you resolve conflicts between product and engineering priorities?",
      "How do you decide when a process needs to change vs when to enforce discipline?"
    ]
  },

  "Jira" => {
    "Junior" => [
      "What is a Jira board and how do you move a ticket across it?",
      "What are the basic issue types in Jira (story, bug, task)?",
      "How do you create and assign a ticket?",
      "What is a backlog?"
    ],
    "Mid" => [
      "How do you manage workflows and transitions in Jira?",
      "Explain boards and backlogs and how they relate to sprints",
      "How do you track sprint progress (burndown charts)?",
      "How do you use labels, components, and epics to organize work?"
    ],
    "Senior" => [
      "What reports do you use to track team health and delivery?",
      "How would you design a Jira workflow for a complex multi-team release process?",
      "How do you use JQL to build custom reports or dashboards?",
      "How do you integrate Jira with CI/CD or other tooling?"
    ],
    "Lead" => [
      "How do you standardize Jira workflows and hierarchy across multiple teams?",
      "How do you decide what metrics to surface to leadership from Jira data?",
      "How do you mentor teams on using Jira effectively without adding overhead?",
      "How do you handle a Jira migration or major process change across the org?"
    ]
  },

  # CRM
  "Salesforce" => {
    "Junior" => [
      "What are objects in Salesforce?",
      "What is the difference between a standard and custom object?",
      "What is a basic workflow or automation you can set up?",
      "What is a Salesforce report vs a dashboard?"
    ],
    "Mid" => [
      "Explain Apex and when you'd use it instead of declarative tools",
      "What are workflows/process builder/flows used for?",
      "How do you set up validation rules and formula fields?",
      "How do you manage user permissions and roles?"
    ],
    "Senior" => [
      "How do integrations work with Salesforce (REST/SOAP APIs, middleware)?",
      "How would you design a scalable data model for a complex org?",
      "How do you handle governor limits in Apex?",
      "How would you plan a large data migration into Salesforce?"
    ],
    "Lead" => [
      "How do you set governance standards for customizations across business units?",
      "How do you decide between declarative automation and custom Apex development?",
      "How do you mentor admins/developers on scalable Salesforce design?",
      "How do you manage a major Salesforce platform upgrade or re-architecture?"
    ]
  },

  # HR
  "HRBP" => {
    "Junior" => [
      "What does an HR Business Partner do day to day?",
      "How do you handle a basic employee question about policy?",
      "What is onboarding and why does it matter?",
      "How do you maintain confidentiality in HR matters?"
    ],
    "Mid" => [
      "How do you resolve employee conflicts?",
      "Describe workforce planning and how you approach it",
      "How do you support a manager through a performance improvement plan?",
      "How do you handle a sensitive employee relations issue?"
    ],
    "Senior" => [
      "How do you partner with leaders on organizational design decisions?",
      "Which HR metrics do you track and why do they matter?",
      "How do you influence leadership without formal authority?",
      "How do you design and roll out a change management initiative?"
    ],
    "Lead" => [
      "How do you build an HR strategy aligned with company-wide business goals?",
      "How do you develop and mentor HR business partners on your team?",
      "How do you handle a large-scale reorganization or workforce reduction?",
      "How do you balance advocating for employees with representing business interests?"
    ]
  },

  # Marketing
  "SEO" => {
    "Junior" => [
      "What affects search rankings at a basic level?",
      "What is a meta description and why does it matter?",
      "What is a backlink?",
      "What is the difference between organic and paid search?"
    ],
    "Mid" => [
      "On-page vs off-page SEO — what's the difference?",
      "How do backlinks work and how do you build them?",
      "How do you conduct keyword research?",
      "How do you use tools like Google Search Console or Analytics?"
    ],
    "Senior" => [
      "How do you measure SEO success beyond rankings (traffic, conversions)?",
      "How would you diagnose a sudden drop in organic traffic?",
      "How do you approach technical SEO (site speed, crawlability, structured data)?",
      "How do you build an SEO strategy for a large multi-page site?"
    ],
    "Lead" => [
      "How do you align SEO strategy with broader marketing and business goals?",
      "How do you mentor a team of SEO specialists?",
      "How do you decide budget allocation between SEO and other channels?",
      "How do you handle an algorithm update that significantly impacts traffic?"
    ]
  },

  # Default (behavioral, always appended)
  "default" => {
    "Junior" => [
      "Tell me about a project you're proud of and your specific contribution to it",
      "How do you approach learning a new technology or tool you haven't used before?",
      "Describe a time you got stuck on a problem — how did you work through it?",
      "How do you make sure your work is correct before submitting it for review?",
      "What are your key strengths?",
      "Why are you looking for a change?",
      "What questions do you have for us?"
    ],
    "Mid" => [
      "Describe a challenging problem you solved and how you diagnosed it",
      "How do you balance quality with delivery deadlines?",
      "Tell me about a time you disagreed with a teammate's approach",
      "How do you approach giving and receiving feedback?",
      "Describe your most challenging project",
      "How do you handle tight deadlines?",
      "What questions do you have for us?"
    ],
    "Senior" => [
      "Describe a system or solution you designed and the trade-offs you considered",
      "How do you approach decisions that affect multiple teams or stakeholders?",
      "Tell me about a time you pushed back on a requirement for good reason",
      "How do you decide between building something new vs using an existing solution?",
      "Describe your most challenging project",
      "Where do you see yourself in 5 years?",
      "What questions do you have for us?"
    ],
    "Lead" => [
      "How do you mentor and grow people on your team?",
      "Describe a time you balanced team priorities against a business deadline",
      "How do you approach strategy and roadmap planning?",
      "Tell me about a difficult people or prioritization decision you had to make",
      "How do you handle underperformance on your team?",
      "Where do you see yourself in 5 years?",
      "What questions do you have for us?"
    ]
  }
  }.freeze

  def index
    @candidates = current_user.visible_candidates.order(:name)
    @jobs       = current_user.visible_jobs.order(:title)
  end

  def generate
    skills = params[:skills].to_s.split(",").map(&:strip)
    role   = params[:role].to_s
    level  = LEVELS.include?(params[:level].to_s) ? params[:level].to_s : "Mid"

    questions = []
    skills.each { |s| questions.concat(questions_for(s, level)) }
    questions.concat(questions_for("default", level))

    render json: { questions: questions.uniq.first(12), role: role, level: level }
  end

  private

  def questions_for(skill, level)
    bank = QUESTIONS[skill]
    return [] unless bank

    bank[level] || []
  end
end
