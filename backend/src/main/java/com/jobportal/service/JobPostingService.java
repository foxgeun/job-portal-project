package com.jobportal.service;

import com.jobportal.entity.JobPosting;
import com.jobportal.repository.JobPostingRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class JobPostingService {

    private final JobPostingRepository jobPostingRepository;

    /** 채용공고 페이지네이션 목록 조회 */
    public Page<JobPosting> getJobPostings(int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        return jobPostingRepository.findAllByOrderByPostedDateDesc(pageable);
    }

    /** ID로 특정 채용공고 조회 */
    public Optional<JobPosting> getJobPostingById(Long id) {
        return jobPostingRepository.findById(id);
    }

    /** 지역으로 채용공고 검색 */
    public List<JobPosting> searchByLocation(String location) {
        return jobPostingRepository.findByLocationContaining(location);
    }

    /** 회사명으로 채용공고 검색 */
    public List<JobPosting> searchByCompany(String company) {
        return jobPostingRepository.findByCompanyNameContaining(company);
    }

    /** 키워드로 채용공고 검색 */
    public List<JobPosting> searchByKeyword(String keyword) {
        return jobPostingRepository.findByTitleContainingIgnoreCase(keyword);
    }

    /** 만료된 채용공고 삭제 */
    @Transactional
    public int deleteExpiredPostings() {
        int deletedCount = jobPostingRepository.deleteExpiredPostings(LocalDate.now());
        log.info("만료된 채용공고 {}건 삭제 완료", deletedCount);
        return deletedCount;
    }
}
