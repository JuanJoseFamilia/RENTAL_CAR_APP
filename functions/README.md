Instrucciones para la Function `onReservationCreate`

1. Instalar dependencias:
   cd functions
   npm install

2. Autenticar con Firebase (si no lo has hecho):
   firebase login

3. Desplegar la función:
   firebase deploy --only functions:onReservationCreate

La función escucha creaciones en `reservations/{reservationId}`, crea una conversación
si no existe, añade un mensaje inicial del administrador y actualiza `lastMessage` y `updatedAt`.
