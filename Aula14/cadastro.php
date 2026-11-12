<?php
header('Content-Type: application/json; charset=utf-8');

$dsn = 'mysql:dbname=banco;host=127.0.0.1;charset=utf8mb4';
$user = 'root';
$password = '';

try {
    $pdo = new PDO($dsn, $user, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $pdo->exec("
        CREATE TABLE IF NOT EXISTS usuarios (
            id INT NOT NULL AUTO_INCREMENT,
            nome VARCHAR(100) NOT NULL,
            email VARCHAR(150) NOT NULL UNIQUE,
            senha VARCHAR(255) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ");

    $nome = trim((string)($_POST['nome'] ?? ''));
    $email = strtolower(trim((string)($_POST['email'] ?? '')));
    $senha = (string)($_POST['senha'] ?? '');

    if ($nome === '' || $email === '' || $senha === '') {
        http_response_code(400);
        echo json_encode([
            'status' => 'erro',
            'mensagem' => 'Preencha nome, e-mail e senha.'
        ]);
        exit;
    }

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        http_response_code(400);
        echo json_encode([
            'status' => 'erro',
            'mensagem' => 'E-mail inválido.'
        ]);
        exit;
    }

    $verifica = $pdo->prepare('SELECT id FROM usuarios WHERE email = ?');
    $verifica->execute([$email]);

    if ($verifica->fetch()) {
        http_response_code(409);
        echo json_encode([
            'status' => 'erro',
            'mensagem' => 'Este e-mail já está cadastrado.'
        ]);
        exit;
    }

    $hash = password_hash($senha, PASSWORD_DEFAULT);

    $stmt = $pdo->prepare('INSERT INTO usuarios (nome, email, senha) VALUES (?, ?, ?)');
    $stmt->execute([$nome, $email, $hash]);

    echo json_encode([
        'status' => 'ok',
        'mensagem' => 'Cadastro realizado com sucesso!',
        'nome' => $nome,
        'email' => $email
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'erro',
        'mensagem' => 'Erro no servidor: ' . $e->getMessage()
    ]);
}
?>
