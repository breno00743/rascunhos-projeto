<?php
header('Content-Type: application/json; charset=utf-8');

$dsn = 'mysql:dbname=banco;host=127.0.0.1;charset=utf8mb4';
$user = 'root';
$password = '';

try {
    $pdo = new PDO($dsn, $user, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $diretorio = __DIR__ . '/fotos';
    if (is_dir($diretorio)) {
        $arquivos = scandir($diretorio);
        foreach ($arquivos as $arquivo) {
            if ($arquivo === '.' || $arquivo === '..') {
                continue;
            }
            $caminho = $diretorio . DIRECTORY_SEPARATOR . $arquivo;
            if (is_file($caminho)) {
                unlink($caminho);
            }
        }
    }

    $pdo->query('DELETE FROM textos');
    $pdo->query('ALTER TABLE textos AUTO_INCREMENT = 1');

    echo json_encode([
        'status' => 'ok',
        'mensagem' => 'Todas as imagens foram apagadas.'
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'erro',
        'mensagem' => 'Erro ao apagar imagens: ' . $e->getMessage()
    ]);
}
?>
