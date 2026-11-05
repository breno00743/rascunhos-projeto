<?php
header('Content-Type: application/json; charset=utf-8');

$dsn = 'mysql:dbname=banco;host=127.0.0.1;charset=utf8mb4';
$user = 'root';
$password = '';

try {
    $pdo = new PDO($dsn, $user, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $pdo->query("CREATE TABLE IF NOT EXISTS `textos` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `texto` VARCHAR(255) NULL,
        `descricao` VARCHAR(255) NULL,
        `foto` VARCHAR(255) NULL,
        PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;");

    foreach (['texto', 'descricao', 'foto'] as $coluna) {
        try {
            $pdo->query("ALTER TABLE `textos` ADD COLUMN `$coluna` VARCHAR(255) NULL");
        } catch (PDOException $e) {
            // ignora se a coluna já existir
        }
    }

    $descricao = trim((string)($_POST['descricao'] ?? $_POST['txt'] ?? ''));
    if ($descricao === '') {
        $descricao = 'Foto enviada';
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

    $sql = 'INSERT INTO `textos` (`texto`, `descricao`, `foto`) VALUES (?, ?, ?)';
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$texto, $descricao, $fotoNome]);

    echo json_encode([
        'status' => 'ok',
        'mensagem' => 'Foto salva com sucesso!',
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