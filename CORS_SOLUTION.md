# Solución al Problema de CORS

## Problema
El servidor `http://barberiaapi.somee.com` no está configurado para permitir peticiones desde `localhost` (CORS).

## Soluciones

### Opción 1: Ejecutar en un dispositivo móvil real (RECOMENDADO)
- CORS solo afecta a aplicaciones web
- En Android/iOS no hay restricciones CORS
- Ejecuta: `flutter run` y selecciona un dispositivo físico o emulador

### Opción 2: Chrome con CORS deshabilitado (Solo para desarrollo)
1. Cierra todas las ventanas de Chrome
2. Abre Chrome desde la línea de comandos con:
   ```bash
   chrome.exe --user-data-dir="C:/temp/chrome_dev" --disable-web-security --disable-features=VizDisplayCompositor
   ```
3. O crea un acceso directo con estos flags

### Opción 3: Usar un proxy local
Puedes usar herramientas como:
- CORS Anywhere (https://cors-anywhere.herokuapp.com/)
- O crear tu propio proxy local

### Opción 4: Configurar CORS en el servidor (Si tienes acceso)
El servidor debe enviar estos headers:
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
```

## Solución Temporal para Desarrollo
He agregado un manejo mejor de errores que te mostrará el error real. Para desarrollo web, la mejor opción es usar un dispositivo móvil o emulador.

