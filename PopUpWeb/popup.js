const activeTabPreview = document.getElementById("active-tab-preview");
const widthInput = document.getElementById("width");
const heightInput = document.getElementById("height");
const windowButton = document.getElementById("window-button");
const sidePanelButton = document.getElementById("sidepanel-button");
const status = document.getElementById("status");
const toolStatusBar = document.getElementById("tool-status-bar");
const statusText = document.getElementById("status-text");
const statusIcon = document.getElementById("status-icon");

const DEFAULT_SETTINGS = { width: 480, height: 720 };
let isToolInstalled = false;

document.addEventListener("DOMContentLoaded", () => {
  chrome.storage.sync.get(DEFAULT_SETTINGS, (settings) => {
    widthInput.value = settings.width;
    heightInput.value = settings.height;
  });
  refreshTabInfo();
  checkToolInstallation();
});

// Función para verificar si pin2top está configurado en el sistema
async function checkToolInstallation() {
  try {
    chrome.runtime.sendNativeMessage(
      "com.popupweb.pin2top",
      { text: "ping" },
      (response) => {
        if (chrome.runtime.lastError) {
          console.error("Error de Pin2Top:", chrome.runtime.lastError.message);
          // No instalado o error de comunicación
          setToolStatus(false);
        } else {
          console.log("Respuesta de Pin2Top recibida:", response);
          // ¡Detectado!
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
  const extensionId = chrome.runtime.id;

  if (installed) {
    toolStatusBar.className = "tool-status tool-status--on";
    statusIcon.textContent = "✅";
    statusText.innerHTML =
      "Herramienta <b>pin2top</b> activa (Siempre Arriba habilitado).";
  } else {
    toolStatusBar.className = "tool-status tool-status--off";
    statusIcon.textContent = "⚠️";
    statusText.innerHTML = `Pin2Top no detectado. ID: <code>${extensionId}</code>. <a href="#" id="open-instructions">Reinstalar</a>`;

    // Re-vincular el evento después de actualizar el HTML
    const link = document.getElementById("open-instructions");
    if (link) {
      link.onclick = openInstructions;
    }
  }
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
  saveDimensions(w, h);

  // Enviar mensaje al background script para abrir la ventana
  chrome.runtime.sendMessage(
    {
      type: "open-popup-window",
      payload: { url: tab.url, width: w, height: h, title: tab.title },
    },
    (response) => {
      if (response?.ok && isToolInstalled && response.uniqueTitleId) {
        // Si la herramienta está instalada y tenemos un ID de título único, enviamos la orden de fijar la ventana
        chrome.runtime.sendNativeMessage("com.popupweb.pin2top", {
          text: "pin_window_by_title_id", // Nueva acción específica
          uniqueTitleId: response.uniqueTitleId, // Pasamos el ID único
        });
      }
      // Pequeña espera antes de cerrar el popup de la extensión
      // Esto asegura que el foco pase a la nueva ventana y AHK la detecte.
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

  // El Side Panel solo permite cargar páginas de la extensión.
  // Usamos viewer.html como puente para cargar la URL externa.
  const targetPath = `viewer.html?url=${encodeURIComponent(tab.url)}`;

  await chrome.sidePanel.setOptions({
    windowId: tab.windowId,
    path: targetPath,
    enabled: true,
  });

  chrome.sidePanel.open({ windowId: tab.windowId });
  window.close();
});

function isValidTab(tab) {
  if (
    !tab ||
    tab.url.startsWith("edge://") ||
    tab.url.startsWith("chrome://")
  ) {
    status.textContent = "No disponible en páginas del sistema.";
    return false;
  }
  return true;
}

function saveDimensions(width, height) {
  chrome.storage.sync.set({ width, height });
}

function refreshTabInfo() {
  chrome.tabs.query({ active: true, lastFocusedWindow: true }, (tabs) => {
    if (tabs[0]) {
      const title = tabs[0].title || "Pestaña actual";
      activeTabPreview.textContent = `Pestaña detectada: ${title.substring(0, 35)}...`;
    }
  });
}
