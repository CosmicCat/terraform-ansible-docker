<html>
<head>
    <title>Hello world!</title>
</head>
<body>

<?php
$host = $_ENV["MARIA"];
$pdo = new PDO("mysql:host=$host;dbname=vacasa", "test", "supersecure");
$sql = 'SELECT first_name, last_name, phone, active, date_created
        FROM users
        ORDER BY last_name';

$q = $pdo->query($sql);?>

<table class="table table-bordered table-condensed">
    <thead>
        <tr>
            <th>First Name</th>
            <th>Last Name</th>
            <th>Phone</th>
            <th>Active?</th>
            <th>Date Created</th>
        </tr>
    </thead>
    <tbody>
        <?php while ($r = $q->fetch()): ?>
            <tr>
                <td><?php echo htmlspecialchars($r['first_name']) ?></td>
                <td><?php echo htmlspecialchars($r['last_name']); ?></td>
                <td><?php echo htmlspecialchars($r['phone']); ?></td>
                <td><?php echo htmlspecialchars($r['active']); ?></td>
                <td><?php echo htmlspecialchars($r['date_created']); ?></td>                
            </tr>
        <?php endwhile; ?>
    </tbody>
</table>
</body>
</html>
