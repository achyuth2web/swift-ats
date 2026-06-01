import "@hotwired/turbo-rails"
import "controllers"
document.addEventListener("turbo:load", () => {
  ["flash-notice","flash-alert"].forEach(id => {
    const el = document.getElementById(id);
    if (el) setTimeout(() => el.style.display = "none", 4000);
  });
});
