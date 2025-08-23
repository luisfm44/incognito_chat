#!/bin/bash

# Nombre del archivo donde guardaremos los logs temporales
LOG1=log_5554.txt
LOG2=log_5556.txt

# Ejecuta en background la app en el primer emulador (5554)
flutter run -d emulator-5554 --debug | tee $LOG1 &
PID1=$!

# Esperamos unos segundos para que arranque
sleep 5

# Ejecuta en background la app en el segundo emulador (5556)
flutter run -d emulator-5556 --debug | tee $LOG2 &
PID2=$!

# Esperamos a que ambas instancias escriban su UUID en consola
echo "⌛ Esperando a que las apps muestren sus UUIDs..."
sleep 10

# Busca los UUID en los logs
UUID1=$(grep -oE '[0-9a-fA-F-]{36}' $LOG1 | head -n 1)
UUID2=$(grep -oE '[0-9a-fA-F-]{36}' $LOG2 | head -n 1)

# Muestra los UUIDs detectados
echo ""
echo "✅ UUID del emulador 1 (emulator-5554): $UUID1"
echo "✅ UUID del emulador 2 (emulator-5556): $UUID2"
echo ""

echo "📱 Ahora puedes probar enviando mensajes entre emuladores:"
echo "- En el emulador 1, pega el UUID del emulador 2 como receptor."
echo "- En el emulador 2, pega el UUID del emulador 1 como receptor."

# Espera a que los procesos terminen (Ctrl+C para detener)
wait $PID1
wait $PID2