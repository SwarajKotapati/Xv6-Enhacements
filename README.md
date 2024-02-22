# Operating System Enhancements 

### Abstract
Operating systems are the linchpin between user applications and hardware, fulfilling critical roles in user interaction, application stability, and system optimization. This project portfolio, completed as part of an advanced operating systems course, delves into enhancing the xv6 operating system. Through a series of assignments, covering bootloader development to virtualization, this portfolio demonstrates a profound understanding of operating system internals, resulting in a more resilient and feature-rich xv6 operating system.

## I. Introduction
This project portfolio represents a deep exploration of advanced operating system design and functionality. Four sections, each addressing unique challenges, collectively contribute to a refined and feature-enriched xv6 operating system. The portfolio outlines a progressive journey from bootloader development to the introduction of virtualization, showcasing a comprehensive understanding of operating system internals.

## II. Solution
### Section 1: Bootloader Development
- **Enhanced Boot Process:** Refined bootloader incorporating linker scripts, stack setup, dynamic kernel loading, and RISC-V Physical Memory Protection (PMP).
- **Secure Boot Functionality:** Integrated SHA-256 hash checks for kernel integrity.
- **In-Depth Analysis:** Utilized GDB for analyzing Boot ROM execution, ensuring a robust foundation for subsequent enhancements.

### Section 2: On-Demand Paging and Copy-On-Write
- **Optimized Memory Management:** Introduced on-demand binary loading, page fault handling, and on-demand heap memory loading.
- **Page Swapping:** Implemented disk-based page swapping for heap memory, enhancing memory usage optimization.
- **Advanced Forking:** Enhanced fork() with copy-on-write (CoW) optimization, improving process memory efficiency.

### Section 3: User-Level Thread Management
- **ULTLib Implementation:** Developed a user-level threading library (ULTLib) for thread creation, switching, yielding, and destruction.
- **Scheduling Algorithms:** Integrated round-robin, first-come-first-serve, and priority scheduling algorithms for efficient multitasking.
- **Rigorous Testing:** Conducted thorough testing for scheduling algorithms, including corner cases and additional test scenarios.

### Section 4: Trap and Emulate Virtualization
- **Virtual Machine (VM) Framework:** Designed a VM within the xv6 framework, allowing execution as user-mode processes.
- **Trap and Emulate Mechanism:** Trapped and emulated privileged instructions, decoded instructions, and emulated Physical Memory Protection (PMP).
- **Extended Capabilities:** Resulted in a robust virtualization framework, expanding the capabilities of the xv6 operating system.

## III. Results
- **Boot Process Enhancement:** Successfully refined the bootloader, ensuring proper stack setup, dynamic kernel loading, and secure boot functionality.
- **Memory Management Optimization:** Introduced on-demand loading, page swapping, and copy-on-write mechanisms, significantly improving memory usage.
- **Multitasking Capabilities:** Implemented user-level threading, enhancing process execution with diverse scheduling algorithms.
- **Virtualization Framework:** Extended xv6 with a virtualization framework, allowing VM execution as user-mode processes.

## IV. Code
Please switch the branches to access the code of each of the above sections. Also, please refer to the "REPORT.pdf" file for deatiled information.

## V. Contribution
All sections were completed independently, showcasing a solo effort in design, coding, and testing. The comprehensive understanding demonstrated throughout the project reflects an in-depth mastery of advanced operating system principles.

## References
[1] Xv6-public: Xv6 OS.
[2] A. Belay, "6.828: Using Virtual Memory," MIT.edu.
[3] F. Embeddev, "RISC-V instruction set manual, volume I: RISC-V user-level ISA."
[4] R. C. F. K. Morris, "xv6: a simple, Unix-like teaching operating system," MIT.edu.

## Contact Information
For any inquiries or issues, please contact [Venkata Swaraj Kotapati] at [kotapatiswaraj06@gmail.com].
