package com.sevalink.sevalinkbackend;

import com.sevalink.sevalinkbackend.model.Category;
import com.sevalink.sevalinkbackend.repository.CategoryRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.Arrays;
import java.util.List;

@Component
public class DataSeeder implements CommandLineRunner {

    @Autowired
    private CategoryRepository categoryRepository;

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

            for (int i = 0; i < categories.size(); i++) {
                Category category = new Category();
                // category.setId((long) (i + 1));
                category.setName(categories.get(i));
                categoryRepository.save(category);
            }
            System.out.println("Seeded categories into database.");
        }
    }
}
