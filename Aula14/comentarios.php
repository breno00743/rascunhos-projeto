<?php
header('Content-Type: application/json; charset=utf-8');

$dsn = 'mysql:dbname=banco;host=127.0.0.1;charset=utf8mb4';
$user = 'root';
$password = '';

try {
    $pdo = new PDO($dsn, $user, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $pdo->exec("
        CREATE TABLE IF NOT EXISTS comentarios (
            id INT NOT NULL AUTO_INCREMENT,
            post_id INT NOT NULL,
            usuario_nome VARCHAR(255) NOT NULL,
            usuario_email VARCHAR(255) NULL,
            texto VARCHAR(255) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            KEY idx_post_id (post_id),
            CONSTRAINT fk_comentarios_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ");

    $postId = (int)($_POST['post_id'] ?? 0);
    $usuario = trim((string)($_POST['usuario'] ?? ''));
    $email = strtolower(trim((string)($_POST['email'] ?? '')));
    $texto = trim((string)($_POST['texto'] ?? ''));

    if ($postId <= 0 || $usuario === '' || $texto === '') {
        http_response_code(400);
        echo json_encode(['status' => 'erro', 'mensagem' => 'Dados inválidos.']);
        exit;
    }

    $stmt = $pdo->prepare('INSERT INTO comentarios (post_id, usuario_nome, usuario_email, texto) VALUES (?, ?, ?, ?)');
    $stmt->execute([$postId, $usuario, $email, $texto]);

    echo json_encode([
        'status' => 'ok',
        'mensagem' => 'Comentário salvo com sucesso!',
        'comentario' => [
            'usuario_nome' => $usuario,
            'texto' => $texto,
        ],
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'erro',
        'mensagem' => $e->getMessage(),
    ]);
}
