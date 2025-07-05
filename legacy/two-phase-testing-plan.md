# Revised Critical Path: Two-Phase Testing Approach
# =================================================

## Phase 1: Technical Validation (July 8-10)
### Participants: 2-3 Core Technical Staff + Kevin
### Objective: Validate exercise functionality and identify critical issues

#### Session 1 (July 8, 4:00-7:00 PM KSA)
**Focus: Day 1 Pulumi Exercise**
- Deploy 5 student environments (student01-05)
- Each person tests Pulumi exercise independently
- Kevin provides technical guidance and troubleshooting
- Document all issues: critical, major, minor
- **Deliverable**: Pulumi exercise issue list with priorities

#### Session 2 (July 9, 4:00-7:00 PM KSA)  
**Focus: Day 2 Tekton Exercise**
- Use same student environments
- Test Tekton CI/CD pipeline functionality
- Focus on integration points and resource contention
- **Deliverable**: Tekton exercise issue list with priorities

#### Session 3 (July 10, 4:00-7:00 PM KSA)
**Focus: Day 3 ArgoCD Exercise**
- Test GitOps workflows and ArgoCD integration
- Validate end-to-end DevOps pipeline
- **Deliverable**: ArgoCD exercise issue list + overall integration assessment

### Phase 1 Success Criteria:
- [ ] All exercises technically functional
- [ ] Critical issues identified and resolution path clear
- [ ] Performance acceptable under light load
- [ ] Infrastructure stable and predictable

## Phase 2: Course Experience Testing (July 12-15)
### Participants: 8-12 Internal Staff (Mixed Technical Levels)
### Objective: Validate course delivery, timing, and student experience

#### Session 4 (July 12, 4:00-7:00 PM KSA)
**Focus: Day 1 Course Experience**
- Deploy 12 student environments (student06-17)
- Simulated course delivery for Day 1 Pulumi
- Test course materials, timing, and flow
- Gather feedback on clarity and completeness

#### Session 5 (July 13, 4:00-7:00 PM KSA)
**Focus: Day 2 Course Experience** 
- Continue with Day 2 Tekton using same environments
- Test course progression and knowledge building
- Validate exercise dependencies and setup

#### Session 6 (July 14, 4:00-7:00 PM KSA)
**Focus: Day 3 Course Experience**
- Complete Day 3 ArgoCD course simulation
- Test full 3-day course progression
- Validate learning objectives achievement

#### Session 7 (July 15, 4:00-7:00 PM KSA)
**Focus: Concurrent Load Testing**
- All 12+ participants work simultaneously
- Stress test infrastructure under realistic load
- Final validation of production readiness

### Phase 2 Success Criteria:
- [ ] Course timing and flow validated
- [ ] Materials clear for target audience
- [ ] Infrastructure performs under realistic load
- [ ] Student experience smooth and engaging

## Outstanding Items (Parallel Track)
### Infrastructure Items:
- [ ] AWS cluster certificate installation (waiting)
- [ ] Repository migration from personal to company GitHub
- [ ] Hardcoded values parameterization
- [ ] Monitoring and alerting setup

### Course Materials Items:
- [ ] PowerPoint templates (resource constraint acknowledged)
- [ ] Exercise instructions finalization
- [ ] Student handout preparation
- [ ] Instructor guide completion

## Risk Management:
1. **Certificate delay**: Continue with current cluster, migrate post-testing
2. **PowerPoint templates**: Focus on content, format later
3. **Repository migration**: Test with current repos, migrate before client delivery
4. **Resource constraints**: Prioritize functional validation over presentation polish

## Communication Plan:
- **Daily updates** during Phase 1 (technical issues)
- **Progress reports** during Phase 2 (course readiness)
- **Go/No-Go decision** by July 16th for client delivery
