import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "candidate", "toEmail", "cc", "subject", "body"]
  static values = {
    candidates: Array,
    templates: Array,
    currentUserName: String,
    defaultCompany: String
  }

  loadTemplate() {
    const templateId = this.templateTarget.value
    if (!templateId) return

    const template = this.templatesValue.find((t) => t.id === templateId)
    if (!template) return

    this.subjectTarget.value = template.subject || ""
    this.bodyTarget.value = template.body || ""

    this.prefillFromCandidate()
  }

  selectCandidate() {
    this.prefillFromCandidate()
  }

  quickLoad(event) {
    const id = event.params.id
    this.templateTarget.value = id
    this.loadTemplate()
  }

  prefillFromCandidate() {
    const candidateId = this.candidateTarget.value
    if (!candidateId) return

    const candidate = this.candidatesValue.find((c) => String(c.id) === String(candidateId))
    if (!candidate) return

    this.toEmailTarget.value = candidate.email || ""
    this.ccTarget.value = candidate.recruiter_email || ""

    const replacements = {
      name: candidate.name || "",
      role: candidate.role || "",
      company: candidate.job_company || this.defaultCompanyValue || "",
      ctc: candidate.ctc_expected || "—",
      date: "[Date]",
      time: "[Time]",
      interviewer: "[Interviewer]",
      mode: "Video Call / In-Person",
      location: "[Location / Meeting Link]",
      recruiter: this.currentUserNameValue || ""
    }

    ;[this.subjectTarget, this.bodyTarget].forEach((field) => {
      let content = field.value
      Object.entries(replacements).forEach(([key, value]) => {
        content = content.replace(new RegExp(`\\{${key}\\}`, "g"), value)
      })
      field.value = content
    })
  }
}
