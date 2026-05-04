const params = new URLSearchParams(window.location.search);
const url = params.get("url");
if (url) {
  const iframe = document.getElementById("content-frame");

  const port = chrome.runtime.connect({ name: "popweb-restore" });
  port.postMessage({ url: url });

  iframe.src = url;
  iframe.onerror = (e) => {
    console.error("El iframe falló al cargar:", e);
  };
  iframe.onload = () => {};
} else {
  console.warn(
    "No se encontró el parámetro 'url' en viewer.html. Cerrando ventana.",
  );
  window.close();
}
