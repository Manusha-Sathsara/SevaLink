package com.sevalink.sevalinkbackend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SearchSuggestion {
    private String text;
    private String type; // "CATEGORY", "WORKER", "SKILL"
}
