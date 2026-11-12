<?php
header('Content-Type: application/json; charset=utf-8');

$dsn = 'mysql:dbname=banco;host=127.0.0.1;charset=utf8mb4';
$user = 'root';
$password = '';

try {
    $pdo = new PDO($dsn, $user, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $pdo->exec("
        CREATE TABLE IF NOT EXISTS notificacoes (
            id INT NOT NULL AUTO_INCREMENT,
            para_email VARCHAR(255) NOT NULL,
            remetente_email VARCHAR(255) NOT NULL,
            remetente_nome VARCHAR(255) NOT NULL,
            mensagem VARCHAR(255) NOT NULL,
            tipo VARCHAR(50) NOT NULL DEFAULT 'amizade',
            lida TINYINT(1) NOT NULL DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            KEY idx_para_email (para_email)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE utf8mb4_general_ci;
    ");

    $email = strtolower(trim((string)($_GET['email'] ?? '')));
    if ($email === '') {
        echo json_encode([]);
        exit;
    }

    $stmt = $pdo->prepare('SELECT id, para_email, remetente_email, remetente_nome, mensagem, tipo, lida FROM notificacoes WHERE para_email = ? ORDER BY id DESC');
    $stmt->execute([$email]);
    echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['erro' => $e->getMessage()]);
}
?>
