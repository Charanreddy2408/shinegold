import '../../models/enums.dart';
import '../../models/executive.dart';
import '../../models/farm.dart';
import '../../models/user.dart';
import '../../models/visit.dart';
import '../../models/visit_form.dart';

class MockSeedData {
  MockSeedData._();

  static const executiveUser = User(
    id: 'exec-1',
    employeeId: 'EXEC001',
    name: 'Rahul Sharma',
    role: UserRole.executive,
    profilePhotoUrl:
        'https://i.pravatar.cc/150?u=rahul',
    address: '12 Green Valley, Pune, Maharashtra',
    mobile: '+91 98765 43210',
    farmsVisitedCount: 24,
    onboardingCount: 5,
  );

  static const superAdminUser = User(
    id: 'admin-1',
    employeeId: 'ADMIN001',
    name: 'Priya Mehta',
    role: UserRole.superAdmin,
    profilePhotoUrl:
        'https://i.pravatar.cc/150?u=priya',
    address: 'Shine Gold HQ, Hyderabad',
    mobile: '+91 91234 56789',
  );

  static final executives = [
    const Executive(
      id: 'exec-1',
      employeeId: 'EXEC001',
      name: 'Rahul Sharma',
      mobile: '+91 98765 43210',
      profilePhotoUrl: 'https://i.pravatar.cc/150?u=rahul',
      farmsAssigned: 8,
      totalVisits: 24,
      onboardedFarmsCount: 5,
      onboardedAcresTotal: 42.5,
    ),
    const Executive(
      id: 'exec-2',
      employeeId: 'EXEC002',
      name: 'Anita Desai',
      mobile: '+91 87654 32109',
      profilePhotoUrl: 'https://i.pravatar.cc/150?u=anita',
      farmsAssigned: 6,
      totalVisits: 18,
      onboardedFarmsCount: 3,
      onboardedAcresTotal: 18,
    ),
    const Executive(
      id: 'exec-3',
      employeeId: 'EMP003',
      name: 'Vikram Patel',
      mobile: '+91 76543 21098',
      profilePhotoUrl: 'https://i.pravatar.cc/150?u=vikram',
      status: ExecutiveStatus.blocked,
      farmsAssigned: 4,
      totalVisits: 12,
      onboardedFarmsCount: 1,
      onboardedAcresTotal: 6.5,
    ),
  ];

  static List<Farm> get farms => [
        Farm(
          id: 'farm-1',
          name: 'Sunrise Organic Farm',
          location: 'Nashik, Maharashtra',
          latitude: 19.9975,
          longitude: 73.7898,
          crop: 'Turmeric',
          harvestDate: DateTime.now().add(const Duration(days: 14)),
          harvestType: 'Organic',
          totalAcres: 12.5,
          assignedExecutiveId: 'exec-1',
          assignedExecutiveName: 'Rahul Sharma',
          farmer: const Farmer(
            id: 'farmer-1',
            name: 'Suresh Kulkarni',
            mobile: '+91 99887 76655',
            gender: Gender.male,
            age: 52,
            photoUrl: 'https://i.pravatar.cc/150?u=suresh',
          ),
          status: FarmVisitStatus.pending,
          healthStatus: FarmHealthStatus.urgentVisit,
          harvestStatus: HarvestStatus.upcoming,
          distanceKm: 2.3,
          visitLogs: [
            VisitLog(
              id: 'log-1',
              farmId: 'farm-1',
              date: DateTime.now().subtract(const Duration(days: 30)),
              durationMinutes: 45,
              visitedBy: 'Rahul Sharma',
              report: 'Crop health good. Minor pest activity noted.',
              photoUrls: ['https://picsum.photos/200?1'],
            ),
          ],
        ),
        Farm(
          id: 'farm-2',
          name: 'Green Valley Estate',
          location: 'Pune, Maharashtra',
          latitude: 18.5204,
          longitude: 73.8567,
          crop: 'Ginger',
          harvestDate: DateTime.now().add(const Duration(days: 7)),
          harvestType: 'Organic',
          totalAcres: 8.0,
          assignedExecutiveId: 'exec-1',
          assignedExecutiveName: 'Rahul Sharma',
          farmer: const Farmer(
            id: 'farmer-2',
            name: 'Lakshmi Reddy',
            mobile: '+91 88776 65544',
            gender: Gender.female,
            age: 45,
            photoUrl: 'https://i.pravatar.cc/150?u=lakshmi',
          ),
          status: FarmVisitStatus.ongoing,
          healthStatus: FarmHealthStatus.needsAttention,
          harvestStatus: HarvestStatus.inProgress,
          lastVisited: DateTime.now().subtract(const Duration(days: 2)),
          distanceKm: 5.1,
        ),
        Farm(
          id: 'farm-3',
          name: 'Hilltop Agro Farm',
          location: 'Satara, Maharashtra',
          latitude: 17.6805,
          longitude: 74.0183,
          crop: 'Turmeric',
          harvestDate: DateTime.now().add(const Duration(days: 21)),
          harvestType: 'Conventional',
          totalAcres: 15.0,
          assignedExecutiveId: 'exec-1',
          assignedExecutiveName: 'Rahul Sharma',
          farmer: const Farmer(
            id: 'farmer-3',
            name: 'Mahesh Jadhav',
            mobile: '+91 77665 54433',
            gender: Gender.male,
            age: 38,
            photoUrl: 'https://i.pravatar.cc/150?u=mahesh',
          ),
          status: FarmVisitStatus.visited,
          healthStatus: FarmHealthStatus.healthy,
          harvestStatus: HarvestStatus.upcoming,
          lastVisited: DateTime.now().subtract(const Duration(days: 5)),
          distanceKm: 8.7,
          visitLogs: [
            VisitLog(
              id: 'log-2',
              farmId: 'farm-3',
              date: DateTime.now().subtract(const Duration(days: 5)),
              durationMinutes: 60,
              visitedBy: 'Rahul Sharma',
              report: 'Excellent crop condition. Ready for harvest planning.',
            ),
          ],
        ),
        Farm(
          id: 'farm-4',
          name: 'Riverbank Fields',
          location: 'Kochi, Kerala',
          latitude: 9.9312,
          longitude: 76.2673,
          crop: 'Cardamom',
          harvestDate: DateTime.now().add(const Duration(days: 45)),
          harvestType: 'Organic',
          totalAcres: 6.5,
          assignedExecutiveId: 'exec-2',
          assignedExecutiveName: 'Anita Desai',
          farmer: const Farmer(
            id: 'farmer-4',
            name: 'Ganesh Pawar',
            mobile: '+91 66554 43322',
            gender: Gender.male,
            age: 41,
            photoUrl: 'https://i.pravatar.cc/150?u=ganesh',
          ),
          status: FarmVisitStatus.pending,
          healthStatus: FarmHealthStatus.needsWater,
          harvestStatus: HarvestStatus.upcoming,
          distanceKm: 12.4,
        ),
        Farm(
          id: 'farm-5',
          name: 'Golden Harvest Plot',
          location: 'Ludhiana, Punjab',
          latitude: 30.9010,
          longitude: 75.8573,
          crop: 'Turmeric',
          harvestDate: DateTime.now().add(const Duration(days: 3)),
          harvestType: 'Organic',
          totalAcres: 10.0,
          assignedExecutiveId: 'exec-1',
          assignedExecutiveName: 'Rahul Sharma',
          farmer: const Farmer(
            id: 'farmer-5',
            name: 'Sunita More',
            mobile: '+91 55443 32211',
            gender: Gender.female,
            age: 36,
            photoUrl: 'https://i.pravatar.cc/150?u=sunita',
          ),
          status: FarmVisitStatus.pending,
          healthStatus: FarmHealthStatus.urgentVisit,
          harvestStatus: HarvestStatus.upcoming,
          distanceKm: 15.2,
        ),
        Farm(
          id: 'farm-6',
          name: 'East Ridge Farm',
          location: 'Kolkata, West Bengal',
          latitude: 22.5726,
          longitude: 88.3639,
          crop: 'Ginger',
          harvestDate: DateTime.now().subtract(const Duration(days: 2)),
          harvestType: 'Organic',
          totalAcres: 9.0,
          assignedExecutiveId: 'exec-2',
          assignedExecutiveName: 'Anita Desai',
          farmer: const Farmer(
            id: 'farmer-6',
            name: 'Deepak Rao',
            mobile: '+91 44332 21100',
            gender: Gender.male,
            age: 48,
            photoUrl: 'https://i.pravatar.cc/150?u=deepak',
          ),
          status: FarmVisitStatus.visited,
          healthStatus: FarmHealthStatus.healthy,
          harvestStatus: HarvestStatus.completed,
          lastVisited: DateTime.now().subtract(const Duration(days: 10)),
          distanceKm: 22.0,
        ),
      ];

  static List<Visit> get visits => [
        Visit(
          id: 'visit-1',
          farmId: 'farm-2',
          farmName: 'Green Valley Estate',
          executiveId: 'exec-1',
          executiveName: 'Rahul Sharma',
          startedAt: DateTime.now().subtract(const Duration(hours: 1)),
          status: VisitStatus.ongoing,
          latitude: 18.5204,
          longitude: 73.8567,
        ),
        Visit(
          id: 'visit-2',
          farmId: 'farm-3',
          farmName: 'Hilltop Agro Farm',
          executiveId: 'exec-1',
          executiveName: 'Rahul Sharma',
          startedAt: DateTime.now().subtract(const Duration(days: 5, hours: 2)),
          endedAt: DateTime.now().subtract(const Duration(days: 5, hours: 1)),
          status: VisitStatus.completed,
          textNote: 'Crop in excellent condition.',
          mcqAnswers: {'q1': 'Good', 'q2': 'No'},
        ),
        Visit(
          id: 'visit-3',
          farmId: 'farm-1',
          farmName: 'Sunrise Organic Farm',
          executiveId: 'exec-1',
          executiveName: 'Rahul Sharma',
          startedAt: DateTime.now().subtract(const Duration(days: 12)),
          endedAt: DateTime.now().subtract(
            const Duration(days: 12) - const Duration(hours: 1),
          ),
          status: VisitStatus.completed,
          textNote: 'Irrigation system checked. Minor pest signs noted.',
        ),
        Visit(
          id: 'visit-4',
          farmId: 'farm-4',
          farmName: 'Riverbank Farms',
          executiveId: 'exec-2',
          executiveName: 'Anita Desai',
          startedAt: DateTime.now().subtract(const Duration(days: 2)),
          endedAt: DateTime.now().subtract(
            const Duration(days: 2) - const Duration(minutes: 45),
          ),
          status: VisitStatus.completed,
          textNote: 'Harvest prep underway.',
        ),
        Visit(
          id: 'visit-5',
          farmId: 'farm-5',
          farmName: 'Meadow Grove',
          executiveId: 'exec-2',
          executiveName: 'Anita Desai',
          startedAt: DateTime.now().subtract(const Duration(days: 8)),
          endedAt: DateTime.now().subtract(
            const Duration(days: 8) - const Duration(hours: 1, minutes: 20),
          ),
          status: VisitStatus.completed,
          textNote: 'Soil moisture levels adequate.',
        ),
        Visit(
          id: 'visit-6',
          farmId: 'farm-6',
          farmName: 'Golden Acres',
          executiveId: 'exec-3',
          executiveName: 'Vikram Patel',
          startedAt: DateTime.now().subtract(const Duration(days: 15)),
          endedAt: DateTime.now().subtract(
            const Duration(days: 15) - const Duration(hours: 2),
          ),
          status: VisitStatus.completed,
          textNote: 'Last visit before account blocked.',
        ),
      ];

  static List<Harvest> get harvests => farms
      .map(
        (f) => Harvest(
          id: 'harvest-${f.id}',
          farmId: f.id,
          farmName: f.name,
          crop: f.crop,
          harvestDate: f.harvestDate,
          harvestType: f.harvestType,
          status: f.harvestStatus,
        ),
      )
      .toList();

  static const mcqQuestions = [
    McqQuestion(
      id: 'q1',
      question: 'How is the overall crop health?',
      options: ['Excellent', 'Good', 'Fair', 'Poor'],
    ),
    McqQuestion(
      id: 'q2',
      question: 'Any pest or disease observed?',
      options: ['No', 'Minor', 'Moderate', 'Severe'],
    ),
    McqQuestion(
      id: 'q3',
      question: 'Irrigation status?',
      options: ['Adequate', 'Needs water', 'Excess water'],
    ),
  ];

  static const demoPassword = 'ChangeMe123!';

  static VisitFormTemplate get visitFormTemplate => VisitFormTemplate(
        id: 'mock-template',
        name: 'Jackfruit Farmer Field Visit Report',
        description: 'Mock template matching backend seed',
        questions: [
          const FormQuestion(
            id: 'q-meta',
            questionKey: 'visit_metadata',
            label: 'Visit Information',
            questionType: FormQuestionType.sectionHeader,
            sortOrder: 0,
            isRequired: false,
          ),
          FormQuestion(
            id: 'q-tree',
            questionKey: 'tree_health',
            label: 'General Health Assessment of Trees',
            questionType: FormQuestionType.singleChoice,
            sortOrder: 10,
            isRequired: true,
            options: [
              const FormQuestionOption(
                id: 'o1',
                value: 'excellent',
                label: 'Excellent',
              ),
              const FormQuestionOption(
                id: 'o2',
                value: 'good',
                label: 'Good',
              ),
              const FormQuestionOption(
                id: 'o3',
                value: 'fair',
                label: 'Fair',
              ),
              const FormQuestionOption(
                id: 'o4',
                value: 'poor',
                label: 'Poor',
              ),
            ],
          ),
          FormQuestion(
            id: 'q-pests',
            questionKey: 'pests_diseases',
            label: 'Observed Pest or Disease Presence',
            questionType: FormQuestionType.multiChoice,
            sortOrder: 20,
            isRequired: true,
            options: [
              const FormQuestionOption(
                id: 'p1',
                value: 'no_major_issues',
                label: 'No major issues',
              ),
              const FormQuestionOption(
                id: 'p2',
                value: 'aphids',
                label: 'Aphids',
              ),
            ],
          ),
          FormQuestion(
            id: 'q-matrix',
            questionKey: 'infrastructure_matrix',
            label: 'Farm Infrastructure Condition',
            questionType: FormQuestionType.matrix,
            sortOrder: 30,
            isRequired: true,
            config: {
              'rows': [
                {'key': 'irrigation_system', 'label': 'Irrigation System'},
                {'key': 'field_fencing', 'label': 'Field Fencing'},
                {'key': 'weed_management', 'label': 'Weed Management'},
                {'key': 'fertigation_system', 'label': 'Fertigation System'},
              ],
              'columns': [
                {'key': 'excellent', 'label': 'Excellent'},
                {'key': 'good', 'label': 'Good'},
                {'key': 'fair', 'label': 'Fair'},
                {'key': 'poor', 'label': 'Poor'},
              ],
            },
          ),
          FormQuestion(
            id: 'q-rating',
            questionKey: 'agronomic_adoption',
            label: 'Farmer adoption of agronomic practices',
            questionType: FormQuestionType.ratingScale,
            sortOrder: 40,
            isRequired: true,
            config: {
              'min': 1,
              'max': 5,
              'min_label': 'Poor',
              'max_label': 'Excellent',
            },
          ),
          FormQuestion(
            id: 'q-assist',
            questionKey: 'assistance_needed',
            label: 'Does the farmer require immediate assistance?',
            questionType: FormQuestionType.singleChoice,
            sortOrder: 50,
            isRequired: true,
            options: [
              const FormQuestionOption(
                id: 'a1',
                value: 'none',
                label: 'No assistance needed',
              ),
              const FormQuestionOption(
                id: 'a2',
                value: 'follow_up_training',
                label: 'Follow-up training',
              ),
            ],
          ),
          const FormQuestion(
            id: 'q-harvest',
            questionKey: 'harvest_schedule_expectations',
            label: 'Harvest schedule and yield expectations',
            questionType: FormQuestionType.textarea,
            sortOrder: 60,
            isRequired: false,
          ),
          const FormQuestion(
            id: 'q-action',
            questionKey: 'action_plan',
            label: 'Action plan / recommendations',
            questionType: FormQuestionType.textarea,
            sortOrder: 80,
            isRequired: false,
          ),
        ],
      );

  static VisitFormContext mockVisitFormContext({
    required String executiveName,
    required String farmLocation,
    required String farmerName,
    DateTime? checkinTime,
  }) =>
      VisitFormContext(
        template: visitFormTemplate,
        prefill: VisitFormPrefill(
          executiveName: executiveName,
          visitDate: DateTime.now().toIso8601String().split('T').first,
          farmLocation: farmLocation,
          farmerContactName: farmerName,
          checkinTime: checkinTime ?? DateTime.now(),
        ),
      );
}
