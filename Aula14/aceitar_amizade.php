<?php
header('Content-Type: application/json; charset=utf-8');

$dsn = 'mysql:dbname=banco;host=127.0.0.1;charset=utf8mb4';
$user = 'root';
$password = '';

try {
    $pdo = new PDO($dsn, $user, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $pdo->exec("
        CREATE TABLE IF NOT EXISTS amizades (
            id INT NOT NULL AUTO_INCREMENT,
            usuario1_email VARCHAR(255) NOT NULL,
            usuario2_email VARCHAR(255) NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT 'aceita',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            UNIQUE KEY uq_amizade (usuario1_email, usuario2_email)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE utf8mb4_general_ci;
    ");

    $email = strtolower(trim((string)($_POST['email'] ?? '')));
    $remetenteEmail = strtolower(trim((string)($_POST['remetente_email'] ?? '')));
    $notificacaoId = (int)($_POST['notificacao_id'] ?? 0);

    if ($email === '' || $remetenteEmail === '') {
        http_response_code(400);
        echo json_encode(['status' => 'erro', 'mensagem' => 'Dados inválidos.']);
        exit;
    }

    $insert = $pdo->prepare('INSERT INTO amizades (usuario1_email, usuario2_email, status) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE status = VALUES(status)');
    $insert->execute([min($email, $remetenteEmail), max($email, $remetenteEmail), 'aceita']);

    if ($notificacaoId > 0) {
        $delete = $pdo->prepare('DELETE FROM notificacoes WHERE id = ? AND para_email = ?');
        $delete->execute([$notificacaoId, $email]);
    }

    $pdo->prepare('UPDATE solicitacoes_amizade SET status = ? WHERE de_email = ? AND para_email = ?')->execute(['aceita', $remetenteEmail, $email]);

    echo json_encode([
        'status' => 'ok',
        'mensagem' => 'Amizade aceita com sucesso!',
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'erro',
        'mensagem' => $e->getMessage(),
    ]);
}
?>
