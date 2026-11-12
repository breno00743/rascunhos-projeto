<?php
header('Content-Type: application/json; charset=utf-8');

$dsn = 'mysql:dbname=banco;host=127.0.0.1;charset=utf8mb4';
$user = 'root';
$password = '';

try {
    $pdo = new PDO($dsn, $user, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $pdo->exec("
        CREATE TABLE IF NOT EXISTS posts (
            id INT NOT NULL AUTO_INCREMENT,
            usuario_nome VARCHAR(255) NOT NULL,
            usuario_email VARCHAR(255) NULL,
            texto LONGTEXT NULL,
            descricao VARCHAR(255) NULL,
            foto VARCHAR(255) NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE utf8mb4_general_ci;
    ");

    $usuarioNome = trim((string)($_POST['usuario'] ?? ''));
    $usuarioEmail = strtolower(trim((string)($_POST['email'] ?? '')));
    $descricao = trim((string)($_POST['descricao'] ?? $_POST['txt'] ?? ''));

    if ($usuarioNome === '') {
        $usuarioNome = 'Usuário';
    }

    if ($descricao === '') {
        $descricao = 'Post publicado';
    }

    $texto = $descricao;
    $fotoNome = null;

    if (isset($_FILES['foto']) && $_FILES['foto']['error'] === UPLOAD_ERR_OK) {
        $diretorio = __DIR__ . '/fotos';
        if (!is_dir($diretorio)) {
            mkdir($diretorio, 0777, true);
        }

        $extensao = strtolower(pathinfo($_FILES['foto']['name'], PATHINFO_EXTENSION));
        $permitidas = ['jpg', 'jpeg', 'png', 'webp'];

        if (!in_array($extensao, $permitidas, true)) {
            http_response_code(400);
            echo json_encode(['status' => 'erro', 'mensagem' => 'Formato de imagem inválido.']);
            exit;
        }

        $nomeArquivo = uniqid('foto_', true) . '.' . $extensao;
        $destino = $diretorio . DIRECTORY_SEPARATOR . $nomeArquivo;

        if (move_uploaded_file($_FILES['foto']['tmp_name'], $destino)) {
            $fotoNome = 'fotos/' . $nomeArquivo;
        }
    }

    $stmt = $pdo->prepare('INSERT INTO posts (usuario_nome, usuario_email, texto, descricao, foto) VALUES (?, ?, ?, ?, ?)');
    $stmt->execute([$usuarioNome, $usuarioEmail, $texto, $descricao, $fotoNome]);

    echo json_encode([
        'status' => 'ok',
        'mensagem' => 'Post salvo com sucesso!',
        'usuario_nome' => $usuarioNome,
        'descricao' => $descricao,
        'foto' => $fotoNome,
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'erro',
        'mensagem' => $e->getMessage(),
    ]);
}
?>
