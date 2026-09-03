// middleware/auth.js
const jwt = require('jsonwebtoken');

// ============================================================================
// protect (middleware)
// ============================================================================
// Ye7keb 9bal ay route "protégée" (mathalan update profile) - ychek
// belli el request 3andha token JWT sa7i7 fel header "Authorization"
// (chekel: "Bearer eyJhbGci..."), w lowkan sa7i7, y7ott "req.userId"
// w "req.userRole" (mel token nfsou) bch el controller yesta3melhom.
//
// 🔵 3lech lezemna hedha: bla ha, ay wa7ed ynajjam yeb3ath request
// "update profile mte3 X" bel ID mte3 X mba3thoud fel body - w
// ynajjam ybeddel data 7ata mch tou3ou! El token ye5tabbar belli el
// user el 7a9i9i howa elli talab el update, mch chkoun 5ir.
// ============================================================================
exports.protect = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'No token provided' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.userId;
    req.userRole = decoded.role;
    next(); // token sa7i7 - kammel lel controller
  } catch (error) {
    return res.status(401).json({ message: 'Invalid or expired token' });
  }
};

// ============================================================================
// isAdmin (middleware)
// ============================================================================
// 🔵 ZID: lezمها tji BA3D "protect" (fel route: protect, isAdmin, controller)
// - "protect" houwa elli y7ott "req.userRole" mel token. Houni ghir
// nchekkou belli el role == 'admin', ken mch heka -> 403 (Forbidden,
// mch 401 - el user connecté sa7i7 lakin ma3andouch el 7a9 le hedhi
// el route bالضبط).
// ============================================================================
exports.isAdmin = (req, res, next) => {
  if (req.userRole !== 'admin') {
    return res.status(403).json({ message: 'Admin access only' });
  }
  next();
};