<?php
header('Content-Type: application/json; charset=utf-8');

$dsn = 'mysql:dbname=banco;host=127.0.0.1;charset=utf8mb4';
$user = 'root';
$password = '';

try {
    $pdo = new PDO($dsn, $user, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $pdo->exec("
        CREATE TABLE IF NOT EXISTS solicitacoes_amizade (
            id INT NOT NULL AUTO_INCREMENT,
            de_nome VARCHAR(255) NOT NULL,
            de_email VARCHAR(255) NOT NULL,
            para_email VARCHAR(255) NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT 'pendente',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            UNIQUE KEY uq_solicitacao (de_email, para_email)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE utf8mb4_general_ci;
    ");

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

    $deNome = trim((string)($_POST['de_nome'] ?? ''));
    $deEmail = strtolower(trim((string)($_POST['de_email'] ?? '')));
    $paraEmail = strtolower(trim((string)($_POST['para_email'] ?? '')));

    if ($deNome === '' || $deEmail === '' || $paraEmail === '') {
        http_response_code(400);
        echo json_encode(['status' => 'erro', 'mensagem' => 'Dados inválidos.']);
        exit;
    }

    if ($deEmail === $paraEmail) {
        http_response_code(400);
        echo json_encode(['status' => 'erro', 'mensagem' => 'Você não pode convidar você mesmo.']);
        exit;
    }

    $verifica = $pdo->prepare('SELECT id FROM solicitacoes_amizade WHERE de_email = ? AND para_email = ? LIMIT 1');
    $verifica->execute([$deEmail, $paraEmail]);
    if ($verifica->fetch()) {
        echo json_encode(['status' => 'ok', 'mensagem' => 'Convite já enviado antes.']);
        exit;
    }

    $stmt = $pdo->prepare('INSERT INTO solicitacoes_amizade (de_nome, de_email, para_email, status) VALUES (?, ?, ?, ?)');
    $stmt->execute([$deNome, $deEmail, $paraEmail, 'pendente']);

    $notificacao = $pdo->prepare('INSERT INTO notificacoes (para_email, remetente_email, remetente_nome, mensagem, tipo) VALUES (?, ?, ?, ?, ?)');
    $notificacao->execute([
        $paraEmail,
        $deEmail,
        $deNome,
        "$deNome enviou um convite de amizade.",
        'amizade'
    ]);

    echo json_encode([
        'status' => 'ok',
        'mensagem' => 'Convite de amizade enviado com sucesso!',
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'erro',
        'mensagem' => $e->getMessage(),
    ]);
}
?>
