package com.sevalink.sevalinkbackend;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import com.sevalink.sevalinkbackend.model.Category;
import com.sevalink.sevalinkbackend.model.Complaint;
import com.sevalink.sevalinkbackend.model.JobPost;
import com.sevalink.sevalinkbackend.model.User;
import com.sevalink.sevalinkbackend.model.UserRole;
import com.sevalink.sevalinkbackend.model.Worker;
import com.sevalink.sevalinkbackend.model.WorkerStatus;
import com.sevalink.sevalinkbackend.repository.CategoryRepository;
import com.sevalink.sevalinkbackend.repository.ComplaintRepository;
import com.sevalink.sevalinkbackend.repository.JobPostRepository;
import com.sevalink.sevalinkbackend.repository.UserRepository;
import com.sevalink.sevalinkbackend.repository.WorkerRepository;

@Component
public class DataSeeder implements CommandLineRunner {

    @Autowired
    private CategoryRepository categoryRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private WorkerRepository workerRepository;

    @Autowired
    private ComplaintRepository complaintRepository;

    @Autowired
    private JobPostRepository jobPostRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) throws Exception {
        if (categoryRepository.count() == 0) {
            List<String> categories = Arrays.asList(
                    "Electrical",
                    "Plumbing",
                    "Carpentry",
                    "Cleaning",
                    "Painting",
                    "General"
            );

            for (String categoryName : categories) {
                Category category = new Category();
                category.setName(categoryName);
                categoryRepository.save(category);
            }
            System.out.println("Seeded categories into database.");
        }

        if (userRepository.countByRole(UserRole.ADMIN) == 0) {
            User admin = new User();
            admin.setFullName("SevaLink Admin");
            admin.setEmail("admin@sevalink.com");
            admin.setPhoneNumber("+94712345678");
            admin.setPasswordHash(passwordEncoder.encode("Admin@123"));
            admin.setRole(UserRole.ADMIN);
            admin.setBirthday(LocalDate.of(1990, 1, 1));
            admin.setIsPhoneVerified(true);
            admin.setIsEmailVerified(true);
            admin.setIsActive(true);
            admin.setCreatedAt(LocalDateTime.now());
            admin.setUpdatedAt(LocalDateTime.now());
            admin.setProfileImageUrl(null);
            admin.setLocation("Colombo, Sri Lanka");
            userRepository.save(admin);
            System.out.println("Seeded default admin user: admin@sevalink.com / Admin@123");
        }

        if (userRepository.countByRole(UserRole.WORKER) == 0) {
            createWorkerSample("Sunil Perera", "sunil@sevalink.com", "+94770123456", "Plumbing", "Pipe repair, Leak fixing", 1200.0, 4.8, 128, WorkerStatus.VERIFIED, LocalDate.of(1994, 2, 12), "Colombo");
            createWorkerSample("Kamal Fernando", "kamal@sevalink.com", "+94771234567", "Electrical", "Fan wiring, Panel repair", 1100.0, 4.6, 96, WorkerStatus.PENDING, LocalDate.of(1992, 5, 28), "Kandy");
            createWorkerSample("Saman Kumara", "saman@sevalink.com", "+94772345678", "Cleaning", "Home cleaning, Deep clean", 950.0, 4.5, 52, WorkerStatus.REJECTED, LocalDate.of(1995, 9, 3), "Galle");
            createWorkerSample("Nadeesha Silva", "nadeesha@sevalink.com", "+94773456789", "Carpentry", "Furniture repair, Door installation", 1300.0, 4.7, 74, WorkerStatus.VERIFIED, LocalDate.of(1993, 11, 15), "Negombo");
            createWorkerSample("Priya Wijesinghe", "priya@sevalink.com", "+94774567890", "Painting", "Interior painting, Wall finishing", 1000.0, 4.4, 68, WorkerStatus.PENDING, LocalDate.of(1996, 7, 20), "Matara");
            System.out.println("Seeded sample worker users and profiles.");
        }

        if (complaintRepository.count() == 0) {
            User client = userRepository.findByEmail("client@example.com").orElseGet(() -> {
                User newClient = new User();
                newClient.setFullName("Sample Client");
                newClient.setEmail("client@example.com");
                newClient.setPhoneNumber("0770000001");
                newClient.setPasswordHash(passwordEncoder.encode("Client@123"));
                newClient.setRole(UserRole.CLIENT);
                newClient.setBirthday(LocalDate.of(1995, 1, 1));
                newClient.setIsPhoneVerified(true);
                newClient.setIsEmailVerified(true);
                newClient.setIsActive(true);
                newClient.setCreatedAt(LocalDateTime.now());
                newClient.setUpdatedAt(LocalDateTime.now());
                return userRepository.save(newClient);
            });

            JobPost jobPost = jobPostRepository.findAll().stream().findFirst().orElseGet(() -> {
                JobPost newJob = new JobPost();
                newJob.setClient(client);
                newJob.setTitle("Plumbing repair request");
                newJob.setDescription("Need urgent plumbing repair at home.");
                newJob.setLocationName("Colombo");
                newJob.setBudgetMin(1500.0);
                newJob.setBudgetMax(2500.0);
                newJob.setUrgency("URGENT");
                newJob.setStatus("OPEN");
                newJob.setCreatedAt(LocalDateTime.now());
                return jobPostRepository.save(newJob);
            });

            Complaint firstComplaint = new Complaint();
            firstComplaint.setJobPost(jobPost);
            firstComplaint.setFiledBy(client);
            firstComplaint.setDescription("The worker requested payment before finishing the service and never responded.");
            firstComplaint.setCreatedAt(LocalDateTime.now());
            complaintRepository.save(firstComplaint);

            Complaint secondComplaint = new Complaint();
            secondComplaint.setJobPost(jobPost);
            secondComplaint.setFiledBy(client);
            secondComplaint.setDescription("I suspect this is a fake job posting and the client is trying to scam workers.");
            secondComplaint.setCreatedAt(LocalDateTime.now());
            complaintRepository.save(secondComplaint);

            System.out.println("Seeded sample complaints for the admin reports page.");
        }
    }

    private Category findCategoryByName(String categoryName) {
        return categoryRepository.findByNameContainingIgnoreCase(categoryName)
                .stream()
                .findFirst()
                .orElse(null);
    }

    private void createWorkerSample(String fullName,
                                    String email,
                                    String phoneNumber,
                                    String categoryName,
                                    String skills,
                                    Double hourlyRate,
                                    Double rating,
                                    Integer totalJobs,
                                    WorkerStatus status,
                                    LocalDate birthday,
                                    String location) {
        User workerUser = new User();
        workerUser.setFullName(fullName);
        workerUser.setEmail(email);
        workerUser.setPhoneNumber(phoneNumber);
        workerUser.setPasswordHash(passwordEncoder.encode("Worker@123"));
        workerUser.setRole(UserRole.WORKER);
        workerUser.setBirthday(birthday);
        workerUser.setIsPhoneVerified(true);
        workerUser.setIsEmailVerified(true);
        workerUser.setIsActive(true);
        workerUser.setCreatedAt(LocalDateTime.now());
        workerUser.setUpdatedAt(LocalDateTime.now());
        workerUser.setProfileImageUrl(null);
        workerUser.setLocation(location);
        userRepository.save(workerUser);

        Worker worker = new Worker();
        worker.setUser(workerUser);
        worker.setCategory(findCategoryByName(categoryName));
        worker.setSkills(skills);
        worker.setHourlyRate(hourlyRate);
        worker.setRating(rating);
        worker.setTotalJobs(totalJobs);
        worker.setStatus(status);
        worker.setIsAvailable(true);
        workerRepository.save(worker);
    }
}
