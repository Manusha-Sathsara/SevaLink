package com.sevalink.sevalinkbackend.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    private static final Logger logger = LoggerFactory.getLogger(EmailService.class);

    @Autowired(required = false)
    private JavaMailSender mailSender;

    @Value("${spring.mail.username:}")
    private String fromEmail;

    @Value("${app.email.enabled:false}")
    private boolean emailEnabled;

    public void sendPasswordResetEmail(String to, String resetToken) {
        // Always log for development
        logger.info("========================================");
        logger.info("🔐 PASSWORD RESET REQUEST");
        logger.info("========================================");
        logger.info("To: {}", to);
        logger.info("From: {}", fromEmail);
        logger.info("Email Enabled: {}", emailEnabled);
        logger.info("MailSender Present: {}", mailSender != null);
        logger.info("Reset PIN: {}", resetToken);
        logger.info("========================================");

        // Only send email if configured
        if (emailEnabled && mailSender != null && !fromEmail.isEmpty()) {
            try {
                SimpleMailMessage message = new SimpleMailMessage();
                message.setTo(to);
                message.setSubject("SevaLink - Your Password Reset PIN code");
                message.setText(buildEmailBody(resetToken));
                message.setFrom(fromEmail);
                message.setReplyTo(fromEmail);

                logger.info("Attempting to send email...");
                mailSender.send(message);
                logger.info("✅ Email sent successfully to: {}", to);
            } catch (Exception e) {
                logger.error("❌ Failed to send email: {}", e.getMessage());
                e.printStackTrace(); // Print full stack trace
            }
        } else {
            logger.warn("⚠️ Email not sent - Check configuration:");
            if (!emailEnabled) logger.warn("  - Email disabled (app.email.enabled=false)");
            if (mailSender == null) logger.warn("  - MailSender bean not available");
            if (fromEmail.isEmpty()) logger.warn("  - From email not configured");
        }
    }

    private String buildEmailBody(String resetToken) {
        return """
            Hello,
            
            We received a request to reset your password for your SevaLink account.
            
            Your password reset PIN code is:
            %s
            
            This code will expire in 5 minutes.
            
            If you didn't request this, please ignore this email.
            
            Best regards,
            SevaLink Team
            """.formatted(resetToken);
    }
}