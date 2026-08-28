package com.jobportal.controller;

import com.jobportal.entity.JobPosting;
import com.jobportal.service.JobPostingService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/jobs")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class JobPostingController {

    private final JobPostingService jobPostingService;

    /**
     * GET /api/jobs?page=0&size=20
     * 채용공고 페이지네이션 목록 조회
     */
    @GetMapping
    public ResponseEntity<Page<JobPosting>> getJobPostings(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Page<JobPosting> postings = jobPostingService.getJobPostings(page, size);
        return ResponseEntity.ok(postings);
    }

    /**
     * GET /api/jobs/{id}
     * 특정 채용공고 상세 조회
     */
    @GetMapping("/{id}")
    public ResponseEntity<JobPosting> getJobPostingById(@PathVariable Long id) {
        return jobPostingService.getJobPostingById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * GET /api/jobs/search?location=서울&company=카카오&keyword=백엔드
     * 지역/회사명/키워드로 채용공고 검색
     */
    @GetMapping("/search")
    public ResponseEntity<List<JobPosting>> searchJobPostings(
            @RequestParam(required = false) String location,
            @RequestParam(required = false) String company,
            @RequestParam(required = false) String keyword) {

        if (location != null && !location.isBlank()) {
            return ResponseEntity.ok(jobPostingService.searchByLocation(location));
        }
        if (company != null && !company.isBlank()) {
            return ResponseEntity.ok(jobPostingService.searchByCompany(company));
        }
        if (keyword != null && !keyword.isBlank()) {
            return ResponseEntity.ok(jobPostingService.searchByKeyword(keyword));
        }

        return ResponseEntity.badRequest().build();
    }
}
