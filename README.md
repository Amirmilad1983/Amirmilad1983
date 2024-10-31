-/school_communication_platform
    ├── /backend
    │      ├── app.py               # Main Flask application
    │      ├── /models               # Database models
    │      ├── /routes               # API endpoints
    │      └── config.py             # Configuration settings
    └── /frontend
           ├── /static               # CSS, JavaScript
           └── /templates            # HTML templates

# backend/app.py

from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_bcrypt import Bcrypt
from flask_jwt_extended import JWTManager

# Initialize Flask app
app = Flask(__name__)

# Configuration
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///school.db'  # SQLite for local development
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SECRET_KEY'] = 'your_secret_key'

# Initialize extensions
db = SQLAlchemy(app)
bcrypt = Bcrypt(app)
jwt = JWTManager(app)
# backend/models.py

from app import db

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(150), unique=True, nullable=False)
    email = db.Column(db.String(150), unique=True, nullable=False)
    password = db.Column(db.String(150), nullable=False)
    role = db.Column(db.String(50), nullable=False)  # Role could be 'admin', 'teacher', 'parent', 'student'
# backend/routes/auth_routes.py

from flask import Blueprint, request, jsonify
from app import db, bcrypt
from models import User
from flask_jwt_extended import create_access_token

auth_routes = Blueprint('auth', __name__)

# Register Route
@auth_routes.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    hashed_password = bcrypt.generate_password_hash(data['password']).decode('utf-8')
    new_user = User(username=data['username'], email=data['email'], password=hashed_password, role=data['role'])
    db.session.add(new_user)
    db.session.commit()
    return jsonify({"message": "User registered successfully"}), 201
# backend/routes/auth_routes.py

@auth_routes.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    user = User.query.filter_by(email=data['email']).first()
    if user and bcrypt.check_password_hash(user.password, data['password']):
        access_token = create_access_token(identity={'username': user.username, 'role': user.role})
        return jsonify(access_token=access_token)
    return jsonify({"error": "Invalid credentials"}), 401
flask run

<!---
Amirmilad1983/Amirmilad1983 is a ✨ special ✨ repository because its `README.md` (this file) appears on your GitHub profile.
You can click the Preview link to take a look at your changes.
--->
# backend/models.py

from datetime import datetime
from app import db

class Message(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    sender_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    receiver_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    content = db.Column(db.Text, nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)

    sender = db.relationship('User', foreign_keys=[sender_id])
    receiver = db.relationship('User', foreign_keys=[receiver_id])
# backend/routes/communication_routes.py

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from models import Message, User

communication_routes = Blueprint('communication', __name__)

@communication_routes.route('/send_message', methods=['POST'])
@jwt_required()
def send_message():
    data = request.get_json()
    sender = get_jwt_identity()
    receiver = User.query.get(data['receiver_id'])

    if not receiver:
        return jsonify({"error": "Receiver not found"}), 404

    new_message = Message(sender_id=sender['id'], receiver_id=receiver.id, content=data['content'])
    db.session.add(new_message)
    db.session.commit()

    return jsonify({"message": "Message sent successfully"}), 201

# backend/routes/communication_routes.py

@communication_routes.route('/messages/<int:user_id>', methods=['GET'])
@jwt_required()
def get_messages(user_id):
    current_user = get_jwt_identity()
    messages = Message.query.filter(
        ((Message.sender_id == current_user['id']) & (Message.receiver_id == user_id)) |
        ((Message.sender_id == user_id) & (Message.receiver_id == current_user['id']))
    ).order_by(Message.timestamp.asc()).all()

    message_list = [{"sender_id": msg.sender_id, "content": msg.content, "timestamp": msg.timestamp} for msg in messages]
    return jsonify(message_list), 200

# backend/models.py

class Announcement(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    content = db.Column(db.Text, nullable=False)
    posted_by = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)

    poster = db.relationship('User', foreign_keys=[posted_by])
@communication_routes.route('/post_announcement', methods=['POST'])
@jwt_required()
def post_announcement():
    data = request.get_json()
    current_user = get_jwt_identity()

    # Only allow admin or teacher roles to post announcements
    if current_user['role'] not in ['admin', 'teacher']:
        return jsonify({"error": "Unauthorized access"}), 403

    new_announcement = Announcement(
        title=data['title'],
        content=data['content'],
        posted_by=current_user['id']
    )
    db.session.add(new_announcement)
    db.session.commit()

    return jsonify({"message": "Announcement posted successfully"}), 201
@communication_routes.route('/announcements', methods=['GET'])
@jwt_required()
def get_announcements():
    announcements = Announcement.query.order_by(Announcement.timestamp.desc()).all()
    announcement_list = [{"title": ann.title, "content": ann.content, "timestamp": ann.timestamp} for ann in announcements]
    return jsonify(announcement_list), 200
