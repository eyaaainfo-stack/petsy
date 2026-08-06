// controllers/authController.js
const User = require('../models/user');
const Owner = require('../models/owner');
const Sitter = require('../models/sitter');
const Courier = require('../models/courier');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// ==========================================
// 1. LOGIN (Mo-waḥḥad lil-acteurs el-koll)
// ==========================================
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // 1. Check user b-email (Admin, Owner, Sitter, walla Courier)
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // 2. Verifi password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    // 3. Taʿmel Token fīh id w role
    const token = jwt.sign(
      { userId: user._id, role: user.role },
      process.env.JWT_SECRET || 'supersecretkey',
      { expiresIn: '7d' }
    );

    // 4. Trajjaʿ el-data lil-Front
    res.status(200).json({
      message: 'Login successful',
      token,
      user: {
        id: user._id,
        email: user.email,
        fullName: user.fullName,
        phone: user.phone,
        role: user.role, // <-- Hna el-Front-end yaʿref el-role (admin/owner/sitter/courier)
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ==========================================
// 2. REGISTER (Lil-Owner, Sitter, Courier)
// ==========================================
exports.register = async (req, res) => {
  try {
    const { email, password, fullName, phone, role, ...otherData } = req.body;

    // Check user déjà mawjūd walla lā
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'Email already exists' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    let newUser;
    const userData = {
      email,
      password: hashedPassword,
      fullName,
      phone,
      ...otherData,
    };

    // Discriminator selection
    switch (role) {
      case 'owner':
        newUser = new Owner(userData);
        break;
      case 'sitter':
        newUser = new Sitter(userData);
        break;
      case 'courier':
        newUser = new Courier(userData);
        break;
      default:
        return res.status(400).json({ message: 'Invalid role for registration' });
    }

    await newUser.save();
    res.status(201).json({ message: 'Account created successfully', user: newUser });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};