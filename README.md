# PopUp WEB

`PopUp WEB` es una extensión para navegadores basados en Chromium diseñada para desacoplar sitios web de las pestañas tradicionales, permitiendo visualizarlos en ventanas emergentes minimalistas o en el panel lateral nativo.

## Características Principales

- **🚀 Ventana Independiente:** Abre cualquier URL en una ventana popup sin marcos de navegación redundantes.
- **📖 Soporte de Side Panel:** Integración con el panel lateral de Chrome/Edge para mantener herramientas o chats siempre visibles.
- **🔓 Bypass de Bloqueo de Frames:** Utiliza un visor basado en `iframe` que permite cargar sitios que restringen su visualización (como Google o GitHub) eliminando las cabeceras de seguridad `X-Frame-Options` y `Content-Security-Policy`.
- **📐 Dimensiones Flexibles:** Control total sobre el ancho y alto de la ventana antes de su apertura.
- **📌 Soporte para `pinontop`:** Arquitectura preparada para comunicarse mediante *Native Messaging* con una herramienta externa para mantener las ventanas siempre al frente.

## Instalación de la Extensión

1. Clona el repositorio.
2. Ve a `chrome://extensions/` en tu navegador.
3. Activa el **Modo de desarrollador**.
4. Selecciona **Cargar descomprimida** y apunta a la subcarpeta `PopUpWeb`.

## Configuración de "Siempre Arriba" (PinOnTop)

Esta función requiere un puente de comunicación nativa con el sistema operativo:

1. Descargue `install_pinontop.exe` de la página [Releases](https://github.com/SystemAlex/PopUP-Web/releases).
2. Ejecuta el archivo `install_pinontop.exe`.
   - **Nota:** No puede requerir privilegios de administrador.
3. El script registrará automáticamente el host en:
   - Google Chrome, Microsoft Edge, Brave, Vivaldi y Opera.
4. Reinicia el navegador para que el cambio surta efecto.
5. ¡La extensión está lista para usar!

## Cómo usarla

1. Navega a cualquier sitio web.
2. Haz clic en el icono de la extensión.
3. Configura las dimensiones deseadas.
4. Selecciona **Ventana** para el modo flotante o **Panel Lateral** para anclarlo a la derecha.
   - Si el indicador de `pinontop` está activo, la ventana se mantendrá siempre al frente.

## Nota

El estado de la herramienta `pinontop` nativa se muestra en la parte inferior del menú de la extensión. Si aparece en amarillo/rojo, sigue las instrucciones de instalación.

---

_Desarrollado para optimizar el flujo de trabajo multiventana._
