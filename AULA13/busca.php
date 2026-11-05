<?php
header('Content-Type: application/json; charset=utf-8');

$dsn = 'mysql:dbname=banco;host=127.0.0.1;charset=utf8mb4';
$user = 'root';
$password = '';

try {
    $pdo = new PDO($dsn, $user, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    if (isset($_GET['id'])) {
        $id = intval($_GET['id']);
        $sql = "SELECT `id`, COALESCE(`descricao`, `texto`) AS `descricao`, `foto` FROM `textos` WHERE `id` > :id ORDER BY `id` ASC LIMIT 1";
        $stmt = $pdo->prepare($sql);
        $stmt->bindParam(':id', $id, PDO::PARAM_INT);
        $stmt->execute();
        $resultado = $stmt->fetch(PDO::FETCH_ASSOC);

        echo json_encode($resultado ?: []);
        exit;
    }

    $sql = "SELECT `id`, COALESCE(`descricao`, `texto`) AS `descricao`, `foto` FROM `textos` ORDER BY `id` ASC";
    $stmt = $pdo->prepare($sql);
    $stmt->execute();
    $resultado = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode($resultado);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['erro' => $e->getMessage()]);
}
?>