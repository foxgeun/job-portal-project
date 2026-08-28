package com.jobportal.repository;

import com.jobportal.entity.JobPosting;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface JobPostingRepository extends JpaRepository<JobPosting, Long> {

    Optional<JobPosting> findByJobUrl(String jobUrl);

    List<JobPosting> findByLocationContaining(String location);

    List<JobPosting> findByCompanyNameContaining(String companyName);

    Page<JobPosting> findAllByOrderByPostedDateDesc(Pageable pageable);

    List<JobPosting> findByTitleContainingIgnoreCase(String keyword);

    @Modifying
    @Query("DELETE FROM JobPosting j WHERE j.expirationDate < :today")
    int deleteExpiredPostings(@org.springframework.data.repository.query.Param("today") LocalDate today);
}
