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

    @Value("${app.email.fail-open:true}")
    private boolean emailFailOpen;

    public boolean sendPasswordResetEmail(String to, String resetToken) {
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

        if (!emailEnabled || mailSender == null || fromEmail.isEmpty()) {
            StringBuilder reason = new StringBuilder("Email cannot be sent. ");
            if (!emailEnabled) reason.append("Email is disabled (app.email.enabled=false). ");
            if (mailSender == null) reason.append("MailSender bean unavailable. ");
            if (fromEmail.isEmpty()) reason.append("From email is not configured. ");
            logger.warn("⚠️ Email not sent - Check configuration: {}", reason.toString());
            return handleEmailFailure(reason.toString());
        }

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
            return true;
        } catch (Exception e) {
            logger.error("❌ Failed to send email: {}", e.getMessage());
            logger.warn("⚠️ Password reset PIN remains valid and is logged above for development.");
            return handleEmailFailure("Unable to deliver password reset email: " + e.getMessage());
        }
    }

    public boolean sendEmail(String to, String subject, String body) {
        // Always log for development
        logger.info("========================================");
        logger.info("📧 EMAIL NOTIFICATION");
        logger.info("========================================");
        logger.info("To: {}", to);
        logger.info("Subject: {}", subject);
        logger.info("========================================");

        if (!emailEnabled || mailSender == null || fromEmail.isEmpty()) {
            StringBuilder reason = new StringBuilder("Email cannot be sent. ");
            if (!emailEnabled) reason.append("Email is disabled (app.email.enabled=false). ");
            if (mailSender == null) reason.append("MailSender bean unavailable. ");
            if (fromEmail.isEmpty()) reason.append("From email is not configured. ");
            logger.warn("⚠️ Email not sent - Check configuration: {}", reason.toString());
            return handleEmailFailure(reason.toString());
        }

        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setTo(to);
            message.setSubject(subject);
            message.setText(body);
            message.setFrom(fromEmail);
            message.setReplyTo(fromEmail);

            logger.info("Attempting to send email...");
            mailSender.send(message);
            logger.info("✅ Email sent successfully to: {}", to);
            return true;
        } catch (Exception e) {
            logger.error("❌ Failed to send email: {}", e.getMessage());
            return handleEmailFailure("Unable to deliver email: " + e.getMessage());
        }
    }

    private boolean handleEmailFailure(String reason) {
        if (emailFailOpen) {
            logger.warn("⚠️ Email delivery failed but fail-open is enabled. Reset PIN is available in logs.");
            logger.warn(reason);
            return false;
        }
        throw new IllegalStateException(reason);
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