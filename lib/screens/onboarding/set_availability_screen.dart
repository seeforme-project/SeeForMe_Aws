import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:seeforyou_aws/models/ModelProvider.dart';
import 'package:seeforyou_aws/screens/home_screen.dart';
import 'dart:convert';

class SetAvailabilityScreen extends StatefulWidget {
  const SetAvailabilityScreen({super.key});

  @override
  State<SetAvailabilityScreen> createState() => _SetAvailabilityScreenState();
}

class _SetAvailabilityScreenState extends State<SetAvailabilityScreen> {
  final Map<String, bool> _selectedDays = {
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
    'Sunday': false,
  };

  final Map<String, TimeOfDay> _startTimes = {
    'Monday': const TimeOfDay(hour: 9, minute: 0),
    'Tuesday': const TimeOfDay(hour: 9, minute: 0),
    'Wednesday': const TimeOfDay(hour: 9, minute: 0),
    'Thursday': const TimeOfDay(hour: 9, minute: 0),
    'Friday': const TimeOfDay(hour: 9, minute: 0),
    'Saturday': const TimeOfDay(hour: 9, minute: 0),
    'Sunday': const TimeOfDay(hour: 9, minute: 0),
  };

  final Map<String, TimeOfDay> _endTimes = {
    'Monday': const TimeOfDay(hour: 17, minute: 0),
    'Tuesday': const TimeOfDay(hour: 17, minute: 0),
    'Wednesday': const TimeOfDay(hour: 17, minute: 0),
    'Thursday': const TimeOfDay(hour: 17, minute: 0),
    'Friday': const TimeOfDay(hour: 17, minute: 0),
    'Saturday': const TimeOfDay(hour: 17, minute: 0),
    'Sunday': const TimeOfDay(hour: 17, minute: 0),
  };

  bool _isLoading = false;

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  Future<void> _saveAvailability() async {
    // Build availability schedule as proper AvailabilitySlot objects
    final List<Map<String, dynamic>> schedule = [];

    _selectedDays.forEach((day, isSelected) {
      if (isSelected) {
        final startTime = _startTimes[day]!;
        final endTime = _endTimes[day]!;

        schedule.add({
          'day': day,
          'startTime': _formatTime(startTime), // Format as HH:mm:ss for AWSTime
          'endTime': _formatTime(endTime),
        });
      }
    });

    if (schedule.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Please select at least one day'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await Amplify.Auth.getCurrentUser();
      safePrint('Current user ID: ${user.userId}');
      safePrint('Availability schedule to save: $schedule');

      // First, verify the volunteer exists
      const getQuery = '''
        query GetVolunteer(\$id: ID!) {
          getVolunteer(id: \$id) {
            id
            owner
            name
            email
            gender
            availabilitySchedule {
              day
              startTime
              endTime
            }
          }
        }
      ''';

      final getRequest = GraphQLRequest<String>(
        document: getQuery,
        variables: {'id': user.userId},
      );

      final getResponse = await Amplify.API.query(request: getRequest).response;
      safePrint('Get volunteer response: ${getResponse.data}');
      safePrint('Get volunteer errors: ${getResponse.errors}');

      if (getResponse.data == null || getResponse.data == 'null') {
        throw Exception('Volunteer not found. Response: ${getResponse.data}');
      }

      final data = jsonDecode(getResponse.data!);
      final volunteerData = data['getVolunteer'];

      if (volunteerData == null) {
        throw Exception('Volunteer not found in response data');
      }

      safePrint('Found volunteer: $volunteerData');

      // Update volunteer with availability schedule
      const updateMutation = '''
        mutation UpdateVolunteer(\$input: UpdateVolunteerInput!) {
          updateVolunteer(input: \$input) {
            id
            name
            email
            gender
            availabilitySchedule {
              day
              startTime
              endTime
            }
          }
        }
      ''';

      final updateRequest = GraphQLRequest<String>(
        document: updateMutation,
        variables: {
          'input': {
            'id': user.userId,
            'availabilitySchedule': schedule, // Send as array of objects, not JSON strings
          }
        },
      );

      safePrint('Update request variables: ${updateRequest.variables}');

      final updateResponse = await Amplify.API.mutate(request: updateRequest).response;
      safePrint('Update response: ${updateResponse.data}');
      safePrint('Update errors: ${updateResponse.errors}');

      if (updateResponse.hasErrors) {
        throw Exception(updateResponse.errors.first.message);
      }

      if (!mounted) return;

      // Navigate to home screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      safePrint('Error saving availability: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Error saving availability: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectTime(String day, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTimes[day]! : _endTimes[day]!,
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTimes[day] = picked;
        } else {
          _endTimes[day] = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Your Availability'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: _selectedDays.keys.map((day) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                day,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Switch(
                                value: _selectedDays[day]!,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDays[day] = value;
                                  });
                                },
                              ),
                            ],
                          ),
                          if (_selectedDays[day]!) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Start Time',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      InkWell(
                                        onTap: () => _selectTime(day, true),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _startTimes[day]!.format(context),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'End Time',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      InkWell(
                                        onTap: () => _selectTime(day, false),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _endTimes[day]!.format(context),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAvailability,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Save Availability'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}