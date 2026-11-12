<?php
header('Content-Type: application/json; charset=utf-8');

$dsn = 'mysql:dbname=banco;host=127.0.0.1;charset=utf8mb4';
$user = 'root';
$password = '';

try {
    $pdo = new PDO($dsn, $user, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $email = strtolower(trim((string)($_POST['email'] ?? '')));
    $senha = (string)($_POST['senha'] ?? '');

    if ($email === '' || $senha === '') {
        http_response_code(400);
        echo json_encode([
            'status' => 'erro',
            'mensagem' => 'Informe e-mail e senha.'
        ]);
        exit;
    }

    $stmt = $pdo->prepare('SELECT nome, senha FROM usuarios WHERE email = ? LIMIT 1');
    $stmt->execute([$email]);
    $usuario = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$usuario || !password_verify($senha, $usuario['senha'])) {
        http_response_code(401);
        echo json_encode([
            'status' => 'erro',
            'mensagem' => 'E-mail ou senha inválidos.'
        ]);
        exit;
    }

    echo json_encode([
        'status' => 'ok',
        'mensagem' => 'Login realizado com sucesso!',
        'nome' => $usuario['nome'],
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
