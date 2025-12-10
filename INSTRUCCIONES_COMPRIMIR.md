# Instrucciones para Comprimir el Proyecto

## Problemas Comunes al Comprimir

Si tienes problemas al comprimir la carpeta, puede deberse a:
1. **Archivos en uso**: Flutter, IDE, o navegadores pueden tener archivos abiertos
2. **Carpetas de build muy grandes**: Los archivos compilados ocupan mucho espacio
3. **Caracteres especiales**: Algunos nombres de archivo pueden causar problemas
4. **Permisos**: Algunos archivos pueden requerir permisos de administrador

## Solución Automática (Recomendada)

### Opción 1: Script Automático
1. **Cierra todos los programas**:
   - Cierra Visual Studio Code / Android Studio
   - Cierra Chrome/Edge si está ejecutando la app
   - Cierra cualquier emulador de Flutter

2. **Ejecuta el script de limpieza**:
   ```
   limpiar_antes_de_comprimir.bat
   ```
   Esto eliminará todos los archivos temporales y de build.

3. **Comprime manualmente**:
   - Haz clic derecho en la carpeta `parte_movil`
   - Selecciona "Enviar a" > "Carpeta comprimida (en zip)"
   - O usa WinRAR / 7-Zip

### Opción 2: Script Completo
Ejecuta:
```
comprimir_proyecto.bat
```
Este script limpia y comprime automáticamente.

## Solución Manual

### Paso 1: Cerrar Programas
- Cierra el IDE (VS Code, Android Studio, etc.)
- Cierra Chrome/Edge
- Cierra cualquier terminal con Flutter ejecutándose
- Cierra emuladores

### Paso 2: Limpiar Archivos
Elimina manualmente estas carpetas (si existen):
- `build/`
- `.dart_tool/`
- `android/build/`
- `android/.gradle/`
- `android/app/build/`
- `ios/Pods/`
- `ios/.symlinks/`
- `windows/build/`
- `linux/build/`
- `web/build/`
- `.idea/`
- `.vscode/`

### Paso 3: Comprimir
1. Haz clic derecho en la carpeta `parte_movil`
2. Selecciona "Enviar a" > "Carpeta comprimida (en zip)"
3. O usa WinRAR / 7-Zip

## Archivos que NO Debes Incluir

Estos archivos se regeneran automáticamente y no son necesarios:
- ✅ **Incluir**: Código fuente (`lib/`), configuración (`pubspec.yaml`, etc.)
- ❌ **Excluir**: `build/`, `.dart_tool/`, `android/build/`, `ios/Pods/`

## Si Aún Tienes Problemas

1. **Ejecuta como Administrador**:
   - Clic derecho en el script > "Ejecutar como administrador"

2. **Usa 7-Zip o WinRAR**:
   - Estos programas manejan mejor archivos bloqueados

3. **Reinicia la computadora**:
   - A veces los archivos quedan bloqueados después de cerrar programas

4. **Comprime solo el código fuente**:
   - Si solo necesitas el código, comprime solo la carpeta `lib/` y `pubspec.yaml`

## Tamaño Esperado

- **Con archivos de build**: 200-500 MB
- **Sin archivos de build**: 5-20 MB

El script de limpieza reduce significativamente el tamaño del archivo comprimido.

