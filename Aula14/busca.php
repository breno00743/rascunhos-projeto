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

    $pdo->exec("
        CREATE TABLE IF NOT EXISTS comentarios (
            id INT NOT NULL AUTO_INCREMENT,
            post_id INT NOT NULL,
            usuario_nome VARCHAR(255) NOT NULL,
            usuario_email VARCHAR(255) NULL,
            texto VARCHAR(255) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            KEY idx_post_id (post_id),
            CONSTRAINT fk_comentarios_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE utf8mb4_general_ci;
    ");

    $pdo->exec("
        CREATE TABLE IF NOT EXISTS curtidas (
            id INT NOT NULL AUTO_INCREMENT,
            post_id INT NOT NULL,
            usuario_email VARCHAR(255) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            UNIQUE KEY uq_curtida (post_id, usuario_email),
            KEY idx_curtiu_post (post_id),
            CONSTRAINT fk_curtidas_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE utf8mb4_general_ci;
    ");

    $emailFiltro = strtolower(trim((string)($_GET['email'] ?? '')));

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

    $postsSql = 'SELECT p.id, p.usuario_nome, p.usuario_email, p.descricao, p.texto, p.foto, COUNT(c.id) AS total_comentarios, COUNT(DISTINCT l.id) AS total_curtidas FROM posts p LEFT JOIN comentarios c ON c.post_id = p.id LEFT JOIN curtidas l ON l.post_id = p.id GROUP BY p.id, p.usuario_nome, p.usuario_email, p.descricao, p.texto, p.foto ORDER BY p.id DESC';
    $postsStmt = $pdo->query($postsSql);
    $posts = $postsStmt->fetchAll(PDO::FETCH_ASSOC);

    $comentariosStmt = $pdo->query('SELECT c.post_id, c.usuario_nome, c.texto FROM comentarios c ORDER BY c.id ASC');
    $comentarios = $comentariosStmt->fetchAll(PDO::FETCH_ASSOC);

    $comentariosPorPost = [];
    foreach ($comentarios as $comentario) {
        $postId = (int)($comentario['post_id'] ?? 0);
        if (!isset($comentariosPorPost[$postId])) {
            $comentariosPorPost[$postId] = [];
        }
        $comentariosPorPost[$postId][] = [
            'usuario_nome' => $comentario['usuario_nome'],
            'texto' => $comentario['texto'],
        ];
    }

    $curtidasPorUsuario = [];
    $amigos = [];
    if ($emailFiltro !== '') {
        $likesStmt = $pdo->prepare('SELECT post_id FROM curtidas WHERE usuario_email = ?');
        $likesStmt->execute([$emailFiltro]);
        foreach ($likesStmt->fetchAll(PDO::FETCH_ASSOC) as $like) {
            $curtidasPorUsuario[(int)($like['post_id'] ?? 0)] = true;
        }

        $amigosStmt = $pdo->prepare('SELECT usuario1_email, usuario2_email FROM amizades WHERE status = ? AND (usuario1_email = ? OR usuario2_email = ?)');
        $amigosStmt->execute(['aceita', $emailFiltro, $emailFiltro]);
        foreach ($amigosStmt->fetchAll(PDO::FETCH_ASSOC) as $amizade) {
            $email1 = strtolower(trim((string)($amizade['usuario1_email'] ?? '')));
            $email2 = strtolower(trim((string)($amizade['usuario2_email'] ?? '')));
            if ($email1 !== '' && $email2 !== '') {
                $amigos[] = $email1;
                $amigos[] = $email2;
            }
        }
    }

    foreach ($posts as &$post) {
        $postId = (int)($post['id'] ?? 0);
        $postEmail = strtolower(trim((string)($post['usuario_email'] ?? '')));
        $post['comentarios'] = $comentariosPorPost[$postId] ?? [];
        $post['total_curtidas'] = (int)($post['total_curtidas'] ?? 0);
        $post['curtido_por_mim'] = !empty($curtidasPorUsuario[$postId]);
        $post['is_amigo'] = $emailFiltro !== '' && $postEmail !== '' && in_array($postEmail, $amigos, true);
    }
    unset($post);

    echo json_encode($posts);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['erro' => $e->getMessage()]);
}
?>
