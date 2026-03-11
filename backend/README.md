# Backend para Flutter Login (Node.js + Express + MariaDB)

Pasos rápidos:

1. Instalar dependencias:

```bash
cd backend
npm install
```

2. Crear base de datos y tabla `users` en MariaDB:

```sql
CREATE DATABASE flutter_login;
USE flutter_login;

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

3. Copiar `.env.example` a `.env` y ajustar credenciales.

4. Iniciar el servidor:

```bash
npm start
```

Notas:
- En desarrollo, si usas el emulador Android, desde Flutter usa `http://10.0.2.2:3000` para conectar a `localhost`.
- Asegura TLS y buenas prácticas antes de pasar a producción.
