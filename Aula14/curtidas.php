<?php
header('Content-Type: application/json; charset=utf-8');

$dsn = 'mysql:dbname=banco;host=127.0.0.1;charset=utf8mb4';
$user = 'root';
$password = '';

try {
    $pdo = new PDO($dsn, $user, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $pdo->exec("
        CREATE TABLE IF NOT EXISTS curtidas (
            id INT NOT NULL AUTO_INCREMENT,
            post_id INT NOT NULL,
            usuario_email VARCHAR(255) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            UNIQUE KEY uq_curtida (post_id, usuario_email),
            KEY idx_post_id (post_id),
            CONSTRAINT fk_curtidas_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ");

    $postId = (int)($_POST['post_id'] ?? 0);
    $email = strtolower(trim((string)($_POST['email'] ?? '')));

    if ($postId <= 0 || $email === '') {
        http_response_code(400);
        echo json_encode(['status' => 'erro', 'mensagem' => 'Dados inválidos.']);
        exit;
    }

    $stmt = $pdo->prepare('SELECT id FROM curtidas WHERE post_id = ? AND usuario_email = ? LIMIT 1');
    $stmt->execute([$postId, $email]);
    $jaCurtiu = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($jaCurtiu) {
        $pdo->prepare('DELETE FROM curtidas WHERE id = ?')->execute([$jaCurtiu['id']]);
        $liked = false;
    } else {
        $pdo->prepare('INSERT INTO curtidas (post_id, usuario_email) VALUES (?, ?)')->execute([$postId, $email]);
        $liked = true;
    }

    $total = $pdo->prepare('SELECT COUNT(*) AS total FROM curtidas WHERE post_id = ?');
    $total->execute([$postId]);
    $resultado = $total->fetch(PDO::FETCH_ASSOC);

    echo json_encode([
        'status' => 'ok',
        'liked' => $liked,
        'total_curtidas' => (int)($resultado['total'] ?? 0),
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'erro',
        'mensagem' => $e->getMessage(),
    ]);
}
