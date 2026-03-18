<?php

declare(strict_types=1);

require_once __DIR__ . '/../includes/auth_guard.php';

$errors = [];
$old = [
    'name' => '',
    'description' => '',
    'price' => '',
    'category' => '',
];

$categories = allowed_listing_categories();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    verify_csrf_or_fail('create_listing_form');

    $name = trim((string)($_POST['name'] ?? ''));
    $description = trim((string)($_POST['description'] ?? ''));
    $price = trim((string)($_POST['price'] ?? ''));
    $category = trim((string)($_POST['category'] ?? ''));

    $old = [
        'name' => $name,
        'description' => $description,
        'price' => $price,
        'category' => $category,
    ];

    if ($name === '') {
        $errors[] = 'Name is required.';
    }
    if ($description === '') {
        $errors[] = 'Description is required.';
    }

    if (!is_numeric($price) || (float)$price <= 0) {
        $errors[] = 'Price must be a numeric value greater than 0.';
    }

    if (!in_array($category, $categories, true)) {
        $errors[] = 'Please choose a valid category.';
    }

    if (!isset($_FILES['image']) || $_FILES['image']['error'] !== UPLOAD_ERR_OK) {
        $errors[] = 'Image upload is required.';
    }

    $relativePath = '';
    if (!$errors) {
        global $config;
        $file = $_FILES['image'];
        $maxBytes = (int)($config['security']['max_upload_bytes'] ?? 5 * 1024 * 1024);

        if ($file['size'] > $maxBytes) {
            $errors[] = 'Image must be 5MB or smaller.';
        }

        $tmpPath = $file['tmp_name'];
        $info = @getimagesize($tmpPath);
        if ($info === false) {
            $errors[] = 'Uploaded file is not a valid image.';
        }

        $allowedMimes = [
            'image/jpeg' => 'jpg',
            'image/png' => 'png',
            'image/webp' => 'webp',
        ];

        $finfo = new finfo(FILEINFO_MIME_TYPE);
        $mime = $finfo->file($tmpPath);

        if (!isset($allowedMimes[$mime])) {
            $errors[] = 'Only JPG, JPEG, PNG, and WEBP images are allowed.';
        }

        $ext = strtolower(pathinfo((string)$file['name'], PATHINFO_EXTENSION));
        $allowedExt = ['jpg', 'jpeg', 'png', 'webp'];

        if (!in_array($ext, $allowedExt, true)) {
            $errors[] = 'Invalid image extension.';
        }

        if (!$errors) {
            $safeExt = $allowedMimes[$mime];
            $filename = bin2hex(random_bytes(16)) . '.' . $safeExt;

            $uploadDir = __DIR__ . '/../uploads/listings';
            if (!is_dir($uploadDir)) {
                mkdir($uploadDir, 0755, true);
            }

            $target = $uploadDir . '/' . $filename;
            $relativePath = 'uploads/listings/' . $filename;

            if (!move_uploaded_file($tmpPath, $target)) {
                $errors[] = 'Could not save uploaded file.';
            }
        }
    }

    if (!$errors) {
        $userId = current_user_id();
        $priceValue = number_format((float)$price, 2, '.', '');

        $stmt = db()->prepare('INSERT INTO listings (user_id, name, description, price, category, image_path, is_approved, created_at) VALUES (?, ?, ?, ?, ?, ?, 1, NOW())');
        if (!$stmt) {
            $errors[] = 'Server error. Please try again later.';
        } else {
            $stmt->bind_param('issdss', $userId, $name, $description, $priceValue, $category, $relativePath);
            if ($stmt->execute()) {
                $stmt->close();
                flash_set('success', 'Listing created successfully.');
                redirect('index.php');
            }
            error_log('Create listing failed: ' . $stmt->error);
            $stmt->close();
            $errors[] = 'Could not create listing right now.';
        }
    }
}

require_once __DIR__ . '/../includes/header.php';
?>
<section class="card form-card">
    <h1>Create Listing</h1>

    <?php foreach ($errors as $error): ?>
        <div class="flash flash-error"><?= e($error) ?></div>
    <?php endforeach; ?>

    <form method="post" enctype="multipart/form-data" novalidate>
        <?= csrf_input('create_listing_form') ?>

        <label for="name">Item Name</label>
        <input id="name" name="name" type="text" maxlength="150" value="<?= e($old['name']) ?>" required>

        <label for="description">Description</label>
        <textarea id="description" name="description" rows="5" required><?= e($old['description']) ?></textarea>

        <label for="price">Price (USD)</label>
        <input id="price" name="price" type="number" min="0.01" step="0.01" value="<?= e($old['price']) ?>" required>

        <label for="category">Category</label>
        <select id="category" name="category" required>
            <option value="">Select a category</option>
            <?php foreach ($categories as $cat): ?>
                <option value="<?= e($cat) ?>" <?= $old['category'] === $cat ? 'selected' : '' ?>><?= e($cat) ?></option>
            <?php endforeach; ?>
        </select>

        <label for="image">Image (JPG, PNG, WEBP, max 5MB)</label>
        <input id="image" name="image" type="file" accept=".jpg,.jpeg,.png,.webp" required>

        <button type="submit">Publish Listing</button>
    </form>
</section>
<?php require_once __DIR__ . '/../includes/footer.php'; ?>
