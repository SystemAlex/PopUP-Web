document.addEventListener("DOMContentLoaded", () => {
  const manifest = chrome.runtime.getManifest();
  const footerLink = document.querySelector(".made-by-text");
  if (footerLink) {
    footerLink.textContent = `v${manifest.version} by ${manifest.author}`;
  }
});
