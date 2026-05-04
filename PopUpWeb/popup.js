const activeTabPreview = document.getElementById("active-tab-preview");
const widthInput = document.getElementById("width");
const heightInput = document.getElementById("height");
const windowButton = document.getElementById("window-button");
const sidePanelButton = document.getElementById("sidepanel-button");
const statusText = document.getElementById("status");
const statusIcon = document.getElementById("status-icon");
const sizePresets = document.getElementById("size-presets");
const alwaysOnTopInput = document.getElementById("always-on-top");

const DEFAULT_SETTINGS = { width: 480, height: 720, alwaysOnTop: true };
let isToolInstalled = false;

document.addEventListener("DOMContentLoaded", () => {
  const manifest = chrome.runtime.getManifest();
  const footerLink = document.querySelector(".made-by-text");
  if (footerLink) {
    footerLink.textContent = `v${manifest.version} by ${manifest.author}`;
  }

  chrome.storage.sync.get(DEFAULT_SETTINGS, (settings) => {
    widthInput.value = settings.width;
    heightInput.value = settings.height;
    alwaysOnTopInput.checked = settings.alwaysOnTop;
    updatePresetSelection();
  });

  sizePresets?.addEventListener("change", (e) => {
    const value = e.target.value;
    if (value !== "custom") {
      const [w, h] = value.split("x");
      widthInput.value = w;
      heightInput.value = h;
    }
  });

  [widthInput, heightInput].forEach((input) => {
    input.addEventListener("input", () => {
      updatePresetSelection();
    });
  });

  alwaysOnTopInput?.addEventListener("change", () => {
    const w = parseInt(widthInput.value);
    const h = parseInt(heightInput.value);
    saveSettings(w, h, alwaysOnTopInput.checked);
  });

  checkToolInstallation();
});

async function checkToolInstallation() {
  try {
    chrome.runtime.sendNativeMessage(
      "com.popupweb.pinontop",
      { text: "ping" },
      (response) => {
        if (chrome.runtime.lastError) {
          console.error("Error de Pin2Top:", chrome.runtime.lastError.message);
          setToolStatus(false);
        } else {
          setToolStatus(true);
        }
      },
    );
  } catch (e) {
    console.error("Error de sendNativeMessage:", e);
    setToolStatus(false);
  }
}

function setToolStatus(installed) {
  isToolInstalled = installed;

  if (installed) {
    statusIcon.innerHTML =
      '<span slot="icon"><svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 20 20" ><path fill="#0E700E" d="M10 2a8 8 0 1 1 0 16a8 8 0 0 1 0-16m3.358 5.646a.5.5 0 0 0-.637-.057l-.07.057L9 11.298L7.354 9.651l-.07-.058a.5.5 0 0 0-.695.696l.057.07l2 2l.07.057a.5.5 0 0 0 .568 0l.07-.058l4.004-4.004l.058-.07a.5.5 0 0 0-.058-.638"></path></svg></span>';
  } else {
    statusIcon.innerHTML =
      '<span slot="icon"><svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 20 20"><path fill="#B10E1C" d="M10 2a8 8 0 1 1 0 16a8 8 0 0 1 0-16M7.81 7.114a.5.5 0 0 0-.638.058l-.058.069a.5.5 0 0 0 .058.638L9.292 10l-2.12 2.121l-.058.07a.5.5 0 0 0 .058.637l.069.058a.5.5 0 0 0 .638-.058L10 10.708l2.121 2.12l.07.058a.5.5 0 0 0 .637-.058l.058-.069a.5.5 0 0 0-.058-.638L10.708 10l2.12-2.121l.058-.07a.5.5 0 0 0-.058-.637l-.069-.058a.5.5 0 0 0-.638.058L10 9.292l-2.121-2.12z"></path></svg></span>';
    statusText.innerHTML =
      "<span class='tool-status tool-status--off'>Herramienta <b>pinontop</b> no detectada. <a href='#' id='open-instructions'>Instalar aquí</a></span>";

    const link = document.getElementById("open-instructions");
    if (link) {
      link.onclick = openInstructions;
    }
  }

  refreshTabInfo();
}

function openInstructions(e) {
  if (e) e.preventDefault();
  chrome.tabs.create({ url: chrome.runtime.getURL("instructions.html") });
}

windowButton.addEventListener("click", async () => {
  const [tab] = await chrome.tabs.query({
    active: true,
    lastFocusedWindow: true,
  });
  if (!isValidTab(tab)) return;

  const w = parseInt(widthInput.value);
  const h = parseInt(heightInput.value);
  const alwaysOnTop = alwaysOnTopInput.checked;
  saveSettings(w, h, alwaysOnTop);

  chrome.runtime.sendMessage(
    {
      type: "open-popup-window",
      payload: {
        url: tab.url,
        width: w,
        height: h,
        title: tab.title,
        alwaysOnTop: alwaysOnTop,
      },
    },
    (response) => {
      if (
        response?.ok &&
        isToolInstalled &&
        response.uniqueTitleId &&
        alwaysOnTop
      ) {
        chrome.runtime.sendNativeMessage("com.popupweb.pinontop", {
          text: "pin_window_by_title_id",
          uniqueTitleId: response.uniqueTitleId,
        });
      }

      if (response?.ok) {
        chrome.tabs.remove(tab.id);
      }
      setTimeout(() => window.close(), 150);
    },
  );
});

sidePanelButton?.addEventListener("click", async () => {
  const [tab] = await chrome.tabs.query({
    active: true,
    lastFocusedWindow: true,
  });
  if (!isValidTab(tab)) return;

  const targetPath = `viewer.html?url=${encodeURIComponent(tab.url)}`;

  const w = parseInt(widthInput.value);
  const h = parseInt(heightInput.value);
  saveSettings(w, h, alwaysOnTopInput.checked);

  await chrome.sidePanel.setOptions({
    path: targetPath,
    enabled: true,
  });

  chrome.sidePanel.open({ windowId: tab.windowId });
  chrome.tabs.remove(tab.id);
  window.close();
});

function isValidTab(tab) {
  if (
    !tab ||
    (!tab.url.startsWith("http://") && !tab.url.startsWith("https://"))
  ) {
    statusText.innerHTML =
      "<span class='tool-status tool-status--off'>Solo disponible en páginas WEB <b>(http:// o https://)</b>.</span>";
    return false;
  }

  if (isToolInstalled) {
    statusText.innerHTML =
      "<span class='tool-status tool-status--on'>Listo...</span>";
  }
  return true;
}

function saveSettings(width, height, alwaysOnTop) {
  chrome.storage.sync.set({ width, height, alwaysOnTop });
}

function refreshTabInfo() {
  chrome.tabs.query({ active: true, lastFocusedWindow: true }, (tabs) => {
    const currentTab = tabs[0];
    if (!currentTab) return;

    const title = currentTab.title || "Pestaña actual";
    activeTabPreview.textContent = `Pestaña detectada: ${title.substring(0, 35)}...`;

    const valid = isValidTab(currentTab);

    [
      widthInput,
      heightInput,
      sizePresets,
      windowButton,
      sidePanelButton,
    ].forEach((el) => {
      if (el) el.disabled = !valid;
    });

    alwaysOnTopInput.disabled = !valid || !isToolInstalled;
  });
}

function updatePresetSelection() {
  if (!sizePresets) return;
  const currentVal = `${widthInput.value}x${heightInput.value}`;
  let matched = false;
  for (const option of sizePresets.options) {
    if (option.value === currentVal) {
      sizePresets.value = currentVal;
      matched = true;
      break;
    }
  }
  if (!matched) sizePresets.value = "custom";
}
