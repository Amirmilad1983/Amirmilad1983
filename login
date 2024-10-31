<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login</title>
</head>
<body>
    <h2>Login</h2>
    <form id="loginForm">
        <label for="email">Email:</label>
        <input type="email" id="email" required>

        <label for="password">Password:</label>
        <input type="password" id="password" required>

        <button type="submit">Login</button>
    </form>

    <script>
        // Handle form submission
        document.getElementById('loginForm').addEventListener('submit', async function(event) {
            event.preventDefault();

            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;

            // Send login request
            const response = await fetch('/login', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email, password })
            });

            const data = await response.json();
            if (response.ok) {
                localStorage.setItem('accessToken', data.access_token);
                alert("Login successful!");
                window.location.href = '/messaging';
            } else {
                alert("Invalid credentials");
            }
        });
    </script>
</body>
</html>

 <!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Messaging</title>
</head>
<body>
    <h2>Messages</h2>
    <div id="messageList"></div>
    <form id="messageForm">
        <input type="text" id="receiver_id" placeholder="Receiver ID" required>
        <textarea id="content" placeholder="Type your message..." required></textarea>
        <button type="submit">Send Message</button>
    </form>

    <script>
        const token = localStorage.getItem('accessToken');

        // Fetch messages for a specific user
        async function loadMessages() {
            const receiverId = document.getElementById('receiver_id').value;
            const response = await fetch(`/messages/${receiverId}`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            const messages = await response.json();
            document.getElementById('messageList').innerHTML = messages.map(msg =>
                `<p><strong>${msg.sender_id}:</strong> ${msg.content}</p>`
            ).join('');
        }

        // Handle sending messages
        document.getElementById('messageForm').addEventListener('submit', async function(event) {
            event.preventDefault();
            const receiverId = document.getElementById('receiver_id').value;
            const content = document.getElementById('content').value;

            await fetch('/send_message', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({ receiver_id: receiverId, content })
            });
            document.getElementById('content').value = '';
            loadMessages();
        });

        // Load messages when page loads
        loadMessages();
    </script>
</body>
</html>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Announcements</title>
</head>
<body>
    <h2>Announcements</h2>
    <div id="announcementList"></div>
    <form id="announcementForm" style="display: none;">
        <input type="text" id="title" placeholder="Title" required>
        <textarea id="content" placeholder="Announcement content" required></textarea>
        <button type="submit">Post Announcement</button>
    </form>

    <script>
        const token = localStorage.getItem('accessToken');

        // Fetch announcements
        async function loadAnnouncements() {
            const response = await fetch('/announcements', {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            const announcements = await response.json();
            document.getElementById('announcementList').innerHTML = announcements.map(ann =>
                `<p><strong>${ann.title}:</strong> ${ann.content}</p>`
            ).join('');
        }

        // Handle posting new announcements
        document.getElementById('announcementForm').addEventListener('submit', async function(event) {
            event.preventDefault();
            const title = document.getElementById('title').value;
            const content = document.getElementById('content').value;

            await fetch('/post_announcement', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({ title, content })
            });
            document.getElementById('title').value = '';
            document.getElementById('content').value = '';
            loadAnnouncements();
        });

        // Load announcements on page load
        loadAnnouncements();
    </script>
</body>
</html>
