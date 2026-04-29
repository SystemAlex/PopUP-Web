# PopUp WEB

`PopUp WEB` es una extensión para navegadores que permite visualizar cualquier sitio web en ventanas flotantes, modo Picture-in-Picture o ventanas independientes con soporte para mantenerse "Siempre Arriba".

## Lo que hace

- **Ventana Popup:** Abre la pestaña actual en una ventana independiente sin bordes de navegador.
- **Modo Picture-in-Picture (PiP):** Permite visualizar el contenido en una ventana flotante que se superpone a otras aplicaciones (ideal para videos o monitoreo).
- **Siempre Arriba (Pin2Top):** Integración con una herramienta nativa para fijar las ventanas y que no se oculten tras otras aplicaciones.
- **Bypass de restricciones:** Elimina automáticamente cabeceras de seguridad (`X-Frame-Options`, `CSP`) para permitir la carga de sitios que normalmente bloquean su uso en marcos o ventanas reducidas.
- **Dimensiones personalizables:** Permite definir el ancho y alto exacto de la ventana.

## Como instalarla en Chrome o Edge

1. Abre `chrome://extensions/` o `edge://extensions/`.
2. Activa el `Modo desarrollador`.
3. Haz clic en `Cargar descomprimida`.
4. Selecciona la carpeta `PopUpWeb` de este repositorio.

### Instalación del modo "Siempre Arriba" (Opcional)

Para que la función de fijar ventana funcione, debes configurar la aplicación compañera:

1. Entra en la carpeta `CompanionApp`.
2. Haz clic derecho en `install.bat` y selecciona **Ejecutar como administrador**.
3. Esto registrará el puente de comunicación para que la extensión pueda controlar el estado de las ventanas.

## Como usarla

1. Navega al sitio que deseas "desprender".
2. Haz clic en el icono de la extensión.
3. Ajusta el ancho y alto deseado.
4. Selecciona una opción:
   - **Ventana:** Abre una ventana popup estándar. Si tienes `pin2top` instalado, se fijará automáticamente arriba.
   - **PiP:** Abre el sitio en modo Picture-in-Picture nativo del navegador.

## Nota

El estado de la herramienta `pin2top` se muestra en la parte inferior del menú de la extensión. Si aparece en amarillo/rojo, sigue las instrucciones de instalación del `CompanionApp`.

---

_Desarrollado para mejorar la productividad multiventana._
