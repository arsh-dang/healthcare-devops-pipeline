const express = require("express");
const mongoose = require("mongoose");
const router = express.Router();

// Import models (assuming they exist)
const User = mongoose.model("User", new mongoose.Schema({
  name: String,
  email: String,
  phone: String,
  dateOfBirth: Date,
  medicalId: String,
  consentGiven: Boolean,
  consentDate: Date,
  dataProcessingPurposes: [String],
  createdAt: Date,
  updatedAt: Date
}));

const AuditLog = mongoose.model("AuditLog", new mongoose.Schema({
  action: String,
  userId: String,
  timestamp: Date,
  details: mongoose.Schema.Types.Mixed,
  ipAddress: String,
  userAgent: String
}));

// Middleware to log GDPR actions
const logGdprAction = (action, userId, details, req) => {
  const auditEntry = new AuditLog({
    action,
    userId,
    timestamp: new Date(),
    details,
    ipAddress: req.ip,
    userAgent: req.get('User-Agent')
  });
  auditEntry.save().catch(err => console.error('Audit log error:', err));
};

// GDPR Data Subject Rights Implementation

// 1. Right of Access (Article 15)
router.get("/access/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    // Log access request
    logGdprAction("DATA_ACCESS_REQUEST", userId, { requestedBy: req.body.requestedBy }, req);

    const userData = {
      personalData: {
        name: user.name,
        email: user.email,
        phone: user.phone,
        dateOfBirth: user.dateOfBirth,
        medicalId: user.medicalId
      },
      consent: {
        given: user.consentGiven,
        date: user.consentDate,
        purposes: user.dataProcessingPurposes
      },
      metadata: {
        createdAt: user.createdAt,
        updatedAt: user.updatedAt
      }
    };

    res.json({
      message: "Data access request processed",
      data: userData,
      processingDate: new Date().toISOString()
    });

  } catch (error) {
    console.error("Data access error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// 2. Right to Rectification (Article 16)
router.put("/rectify/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const { corrections } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    // Apply corrections
    Object.keys(corrections).forEach(key => {
      if (user[key] !== undefined) {
        user[key] = corrections[key];
      }
    });
    user.updatedAt = new Date();

    await user.save();

    // Log rectification
    logGdprAction("DATA_RECTIFICATION", userId, { corrections, requestedBy: req.body.requestedBy }, req);

    res.json({
      message: "Data rectification completed",
      updatedFields: Object.keys(corrections),
      rectificationDate: new Date().toISOString()
    });

  } catch (error) {
    console.error("Data rectification error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// 3. Right to Erasure (Article 17) - "Right to be forgotten"
router.delete("/erase/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const { reason } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    // Check for legal exceptions (simplified)
    const hasLegalObligation = false; // In real implementation, check for legal holds
    const publicInterest = false; // Check for public interest reasons
    const researchPurposes = false; // Check for research exemptions

    if (hasLegalObligation || publicInterest || researchPurposes) {
      return res.status(409).json({
        error: "Erasure cannot be completed due to legal obligations",
        reason: "Legal exception applies"
      });
    }

    // Perform erasure
    await User.findByIdAndDelete(userId);

    // Log erasure
    logGdprAction("DATA_ERASURE", userId, { reason, requestedBy: req.body.requestedBy }, req);

    res.json({
      message: "Data erasure completed",
      userId,
      erasureDate: new Date().toISOString()
    });

  } catch (error) {
    console.error("Data erasure error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// 4. Right to Restriction of Processing (Article 18)
router.put("/restrict/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const { restrictionType, reason } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    // Add restriction flag (in real implementation, this would affect data processing)
    user.processingRestricted = true;
    user.restrictionType = restrictionType;
    user.restrictionReason = reason;
    user.restrictionDate = new Date();

    await user.save();

    // Log restriction
    logGdprAction("DATA_RESTRICTION", userId, { restrictionType, reason, requestedBy: req.body.requestedBy }, req);

    res.json({
      message: "Data processing restricted",
      restrictionType,
      restrictionDate: new Date().toISOString()
    });

  } catch (error) {
    console.error("Data restriction error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// 5. Right to Data Portability (Article 20)
router.get("/portability/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const format = req.query.format || 'json';

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    const portableData = {
      personalData: {
        name: user.name,
        email: user.email,
        phone: user.phone,
        dateOfBirth: user.dateOfBirth,
        medicalId: user.medicalId
      },
      consent: {
        given: user.consentGiven,
        date: user.consentDate,
        purposes: user.dataProcessingPurposes
      },
      metadata: {
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
        exportDate: new Date().toISOString()
      }
    };

    // Log portability request
    logGdprAction("DATA_PORTABILITY", userId, { format, requestedBy: req.body.requestedBy }, req);

    if (format === 'json') {
      res.setHeader('Content-Type', 'application/json');
      res.setHeader('Content-Disposition', `attachment; filename="user-data-${userId}.json"`);
      res.json(portableData);
    } else if (format === 'xml') {
      // Convert to XML format
      const xmlData = `<user-data>
        <personal-data>
          <name>${user.name}</name>
          <email>${user.email}</email>
          <phone>${user.phone}</phone>
          <date-of-birth>${user.dateOfBirth}</date-of-birth>
          <medical-id>${user.medicalId}</medical-id>
        </personal-data>
        <consent>
          <given>${user.consentGiven}</given>
          <date>${user.consentDate}</date>
          <purposes>${user.dataProcessingPurposes.join(', ')}</purposes>
        </consent>
        <metadata>
          <created-at>${user.createdAt}</created-at>
          <updated-at>${user.updatedAt}</updated-at>
          <export-date>${new Date().toISOString()}</export-date>
        </metadata>
      </user-data>`;

      res.setHeader('Content-Type', 'application/xml');
      res.setHeader('Content-Disposition', `attachment; filename="user-data-${userId}.xml"`);
      res.send(xmlData);
    } else {
      res.status(400).json({ error: "Unsupported format. Use 'json' or 'xml'" });
    }

  } catch (error) {
    console.error("Data portability error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// 6. Right to Object (Article 21)
router.put("/object/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const { objectionType, reason } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    // Record objection
    user.objectionFiled = true;
    user.objectionType = objectionType;
    user.objectionReason = reason;
    user.objectionDate = new Date();

    await user.save();

    // Log objection
    logGdprAction("DATA_OBJECTION", userId, { objectionType, reason, requestedBy: req.body.requestedBy }, req);

    res.json({
      message: "Objection recorded",
      objectionType,
      objectionDate: new Date().toISOString()
    });

  } catch (error) {
    console.error("Data objection error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Consent Management
router.post("/consent/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const { consentGiven, purposes, withdrawal } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    if (withdrawal) {
      // Handle consent withdrawal
      user.consentGiven = false;
      user.consentWithdrawnDate = new Date();
      user.dataProcessingPurposes = [];
    } else {
      // Handle consent grant/update
      user.consentGiven = consentGiven;
      user.consentDate = new Date();
      user.dataProcessingPurposes = purposes || [];
    }

    await user.save();

    // Log consent action
    logGdprAction(withdrawal ? "CONSENT_WITHDRAWAL" : "CONSENT_UPDATE", userId,
      { consentGiven, purposes, withdrawal, requestedBy: req.body.requestedBy }, req);

    res.json({
      message: withdrawal ? "Consent withdrawn" : "Consent updated",
      consentGiven: user.consentGiven,
      purposes: user.dataProcessingPurposes,
      actionDate: new Date().toISOString()
    });

  } catch (error) {
    console.error("Consent management error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Data Breach Notification Endpoint (for internal use)
router.post("/breach-notification", async (req, res) => {
  try {
    const { breachDetails, affectedUsers } = req.body;

    // Log breach
    logGdprAction("DATA_BREACH_DETECTED", "SYSTEM", {
      breachDetails,
      affectedUsersCount: affectedUsers.length,
      notificationRequired: true
    }, req);

    // In a real implementation, this would:
    // 1. Notify supervisory authority within 72 hours
    // 2. Notify affected individuals without undue delay
    // 3. Document the breach response

    res.json({
      message: "Breach notification logged",
      breachId: `breach-${Date.now()}`,
      loggedAt: new Date().toISOString(),
      notificationRequired: true
    });

  } catch (error) {
    console.error("Breach notification error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Audit Trail Access (for compliance monitoring)
router.get("/audit/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const { startDate, endDate } = req.query;

    const query = { userId };
    if (startDate && endDate) {
      query.timestamp = {
        $gte: new Date(startDate),
        $lte: new Date(endDate)
      };
    }

    const auditLogs = await AuditLog.find(query).sort({ timestamp: -1 }).limit(100);

    res.json({
      userId,
      auditLogs: auditLogs.map(log => ({
        action: log.action,
        timestamp: log.timestamp,
        details: log.details,
        ipAddress: log.ipAddress
      })),
      totalLogs: auditLogs.length
    });

  } catch (error) {
    console.error("Audit access error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

module.exports = router;
