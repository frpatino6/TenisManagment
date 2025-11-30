const fs = require('fs');
const collection = JSON.parse(fs.readFileSync('postman_collection.json', 'utf8'));

// Professor Dashboard (Firebase) endpoints
const professorDashboard = {
  name: 'Professor Dashboard (Firebase)',
  item: [
    {
      name: 'Get Professor Info',
      request: {
        method: 'GET',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: { raw: '{{base_url}}/professor-dashboard/me', host: ['{{base_url}}'], path: ['professor-dashboard', 'me'] }
      }
    },
    {
      name: 'Get Students',
      request: {
        method: 'GET',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: { raw: '{{base_url}}/professor-dashboard/students', host: ['{{base_url}}'], path: ['professor-dashboard', 'students'] }
      }
    },
    {
      name: 'Get Schedule By Date',
      request: {
        method: 'GET',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: {
          raw: '{{base_url}}/professor-dashboard/schedule/by-date?date=2024-01-15',
          host: ['{{base_url}}'],
          path: ['professor-dashboard', 'schedule', 'by-date'],
          query: [{ key: 'date', value: '2024-01-15' }]
        }
      }
    },
    {
      name: 'Get Today Schedule',
      request: {
        method: 'GET',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: { raw: '{{base_url}}/professor-dashboard/schedule/today', host: ['{{base_url}}'], path: ['professor-dashboard', 'schedule', 'today'] }
      }
    },
    {
      name: 'Get Week Schedule',
      request: {
        method: 'GET',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: { raw: '{{base_url}}/professor-dashboard/schedule/week', host: ['{{base_url}}'], path: ['professor-dashboard', 'schedule', 'week'] }
      }
    },
    {
      name: 'Get Earnings Stats',
      request: {
        method: 'GET',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: { raw: '{{base_url}}/professor-dashboard/earnings', host: ['{{base_url}}'], path: ['professor-dashboard', 'earnings'] }
      }
    },
    {
      name: 'Update Profile',
      request: {
        method: 'PUT',
        header: [
          { key: 'Authorization', value: 'Bearer {{firebase_token}}' },
          { key: 'Content-Type', value: 'application/json' }
        ],
        body: {
          mode: 'raw',
          raw: JSON.stringify({ name: 'Profesor Actualizado', phone: '1234567890', specialties: ['Técnica', 'Físico'] }, null, 2)
        },
        url: { raw: '{{base_url}}/professor-dashboard/profile', host: ['{{base_url}}'], path: ['professor-dashboard', 'profile'] }
      }
    },
    {
      name: 'Create Schedule',
      request: {
        method: 'POST',
        header: [
          { key: 'Authorization', value: 'Bearer {{firebase_token}}' },
          { key: 'Content-Type', value: 'application/json' }
        ],
        body: {
          mode: 'raw',
          raw: JSON.stringify({ date: '2024-01-15', startTime: '2024-01-15T10:00:00Z', endTime: '2024-01-15T11:00:00Z' }, null, 2)
        },
        url: { raw: '{{base_url}}/professor-dashboard/schedules', host: ['{{base_url}}'], path: ['professor-dashboard', 'schedules'] }
      }
    },
    {
      name: 'Get My Schedules',
      request: {
        method: 'GET',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: { raw: '{{base_url}}/professor-dashboard/schedules', host: ['{{base_url}}'], path: ['professor-dashboard', 'schedules'] }
      }
    },
    {
      name: 'Delete Schedule',
      request: {
        method: 'DELETE',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: { raw: '{{base_url}}/professor-dashboard/schedules/{{schedule_id}}', host: ['{{base_url}}'], path: ['professor-dashboard', 'schedules', '{{schedule_id}}'] }
      }
    },
    {
      name: 'Block Schedule',
      request: {
        method: 'PUT',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: { raw: '{{base_url}}/professor-dashboard/schedules/{{schedule_id}}/block', host: ['{{base_url}}'], path: ['professor-dashboard', 'schedules', '{{schedule_id}}', 'block'] }
      }
    },
    {
      name: 'Unblock Schedule',
      request: {
        method: 'PUT',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: { raw: '{{base_url}}/professor-dashboard/schedules/{{schedule_id}}/unblock', host: ['{{base_url}}'], path: ['professor-dashboard', 'schedules', '{{schedule_id}}', 'unblock'] }
      }
    },
    {
      name: 'Confirm Class',
      request: {
        method: 'PUT',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: { raw: '{{base_url}}/professor-dashboard/schedule/{{class_id}}/confirm', host: ['{{base_url}}'], path: ['professor-dashboard', 'schedule', '{{class_id}}', 'confirm'] }
      }
    },
    {
      name: 'Cancel Class',
      request: {
        method: 'PUT',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: { raw: '{{base_url}}/professor-dashboard/schedule/{{class_id}}/cancel', host: ['{{base_url}}'], path: ['professor-dashboard', 'schedule', '{{class_id}}', 'cancel'] }
      }
    },
    {
      name: 'Complete Class',
      request: {
        method: 'PUT',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: { raw: '{{base_url}}/professor-dashboard/schedules/{{schedule_id}}/complete', host: ['{{base_url}}'], path: ['professor-dashboard', 'schedules', '{{schedule_id}}', 'complete'] }
      }
    },
    {
      name: 'Cancel Booking',
      request: {
        method: 'PUT',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: { raw: '{{base_url}}/professor-dashboard/schedules/{{schedule_id}}/cancel-booking', host: ['{{base_url}}'], path: ['professor-dashboard', 'schedules', '{{schedule_id}}', 'cancel-booking'] }
      }
    }
  ]
};

// Pricing endpoints
const pricing = {
  name: 'Pricing',
  item: [
    {
      name: 'Get Base Pricing',
      request: {
        method: 'GET',
        url: { raw: '{{base_url}}/pricing/base', host: ['{{base_url}}'], path: ['pricing', 'base'] }
      }
    },
    {
      name: 'Get Professor Pricing',
      request: {
        method: 'GET',
        url: { raw: '{{base_url}}/pricing/professor/{{professor_id}}', host: ['{{base_url}}'], path: ['pricing', 'professor', '{{professor_id}}'] }
      }
    },
    {
      name: 'Get My Pricing',
      request: {
        method: 'GET',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: { raw: '{{base_url}}/pricing/my-pricing', host: ['{{base_url}}'], path: ['pricing', 'my-pricing'] }
      }
    },
    {
      name: 'Update My Pricing',
      request: {
        method: 'PUT',
        header: [
          { key: 'Authorization', value: 'Bearer {{firebase_token}}' },
          { key: 'Content-Type', value: 'application/json' }
        ],
        body: {
          mode: 'raw',
          raw: JSON.stringify({ individualClass: 55000, groupClass: 40000, courtRental: 30000 }, null, 2)
        },
        url: { raw: '{{base_url}}/pricing/my-pricing', host: ['{{base_url}}'], path: ['pricing', 'my-pricing'] }
      }
    },
    {
      name: 'Reset My Pricing',
      request: {
        method: 'DELETE',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: { raw: '{{base_url}}/pricing/my-pricing', host: ['{{base_url}}'], path: ['pricing', 'my-pricing'] }
      }
    }
  ]
};

// Analytics endpoints
const analytics = {
  name: 'Analytics',
  item: [
    {
      name: 'Get Overview',
      request: {
        method: 'GET',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: {
          raw: '{{base_url}}/professor-dashboard/analytics/overview?period=month',
          host: ['{{base_url}}'],
          path: ['professor-dashboard', 'analytics', 'overview'],
          query: [{ key: 'period', value: 'month' }]
        }
      }
    },
    {
      name: 'Get Revenue Data',
      request: {
        method: 'GET',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: {
          raw: '{{base_url}}/professor-dashboard/analytics/revenue?period=month',
          host: ['{{base_url}}'],
          path: ['professor-dashboard', 'analytics', 'revenue'],
          query: [{ key: 'period', value: 'month' }]
        }
      }
    },
    {
      name: 'Get Bookings Data',
      request: {
        method: 'GET',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: {
          raw: '{{base_url}}/professor-dashboard/analytics/bookings?period=month',
          host: ['{{base_url}}'],
          path: ['professor-dashboard', 'analytics', 'bookings'],
          query: [{ key: 'period', value: 'month' }]
        }
      }
    },
    {
      name: 'Get Students Data',
      request: {
        method: 'GET',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: {
          raw: '{{base_url}}/professor-dashboard/analytics/students?period=month',
          host: ['{{base_url}}'],
          path: ['professor-dashboard', 'analytics', 'students'],
          query: [{ key: 'period', value: 'month' }]
        }
      }
    },
    {
      name: 'Get Revenue Breakdown',
      request: {
        method: 'GET',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: {
          raw: '{{base_url}}/professor-dashboard/analytics/revenue/breakdown?period=month&startDate=2024-01-01&endDate=2024-01-31',
          host: ['{{base_url}}'],
          path: ['professor-dashboard', 'analytics', 'revenue', 'breakdown'],
          query: [
            { key: 'period', value: 'month' },
            { key: 'startDate', value: '2024-01-01' },
            { key: 'endDate', value: '2024-01-31' }
          ]
        }
      }
    },
    {
      name: 'Get Bookings Breakdown',
      request: {
        method: 'GET',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: {
          raw: '{{base_url}}/professor-dashboard/analytics/bookings/breakdown?period=month&startDate=2024-01-01&endDate=2024-01-31',
          host: ['{{base_url}}'],
          path: ['professor-dashboard', 'analytics', 'bookings', 'breakdown'],
          query: [
            { key: 'period', value: 'month' },
            { key: 'startDate', value: '2024-01-01' },
            { key: 'endDate', value: '2024-01-31' }
          ]
        }
      }
    },
    {
      name: 'Get Revenue Trend',
      request: {
        method: 'GET',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: {
          raw: '{{base_url}}/professor-dashboard/analytics/revenue/trend?period=month&startDate=2024-01-01&endDate=2024-01-31',
          host: ['{{base_url}}'],
          path: ['professor-dashboard', 'analytics', 'revenue', 'trend'],
          query: [
            { key: 'period', value: 'month' },
            { key: 'startDate', value: '2024-01-01' },
            { key: 'endDate', value: '2024-01-31' }
          ]
        }
      }
    },
    {
      name: 'Get Bookings Trend',
      request: {
        method: 'GET',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: {
          raw: '{{base_url}}/professor-dashboard/analytics/bookings/trend?period=month&startDate=2024-01-01&endDate=2024-01-31',
          host: ['{{base_url}}'],
          path: ['professor-dashboard', 'analytics', 'bookings', 'trend'],
          query: [
            { key: 'period', value: 'month' },
            { key: 'startDate', value: '2024-01-01' },
            { key: 'endDate', value: '2024-01-31' }
          ]
        }
      }
    },
    {
      name: 'Get Students Breakdown',
      request: {
        method: 'GET',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: {
          raw: '{{base_url}}/professor-dashboard/analytics/students/breakdown?period=month&startDate=2024-01-01&endDate=2024-01-31',
          host: ['{{base_url}}'],
          path: ['professor-dashboard', 'analytics', 'students', 'breakdown'],
          query: [
            { key: 'period', value: 'month' },
            { key: 'startDate', value: '2024-01-01' },
            { key: 'endDate', value: '2024-01-31' }
          ]
        }
      }
    },
    {
      name: 'Get Students Trend',
      request: {
        method: 'GET',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: {
          raw: '{{base_url}}/professor-dashboard/analytics/students/trend?period=month&startDate=2024-01-01&endDate=2024-01-31',
          host: ['{{base_url}}'],
          path: ['professor-dashboard', 'analytics', 'students', 'trend'],
          query: [
            { key: 'period', value: 'month' },
            { key: 'startDate', value: '2024-01-01' },
            { key: 'endDate', value: '2024-01-31' }
          ]
        }
      }
    },
    {
      name: 'Get Occupancy Details',
      request: {
        method: 'GET',
        header: [{ key: 'Authorization', value: 'Bearer {{firebase_token}}' }],
        url: {
          raw: '{{base_url}}/professor-dashboard/analytics/occupancy/details?period=month&startDate=2024-01-01&endDate=2024-01-31',
          host: ['{{base_url}}'],
          path: ['professor-dashboard', 'analytics', 'occupancy', 'details'],
          query: [
            { key: 'period', value: 'month' },
            { key: 'startDate', value: '2024-01-01' },
            { key: 'endDate', value: '2024-01-31' }
          ]
        }
      }
    }
  ]
};

collection.item.push(professorDashboard, pricing, analytics);
fs.writeFileSync('postman_collection.json', JSON.stringify(collection, null, 2));
console.log('Added all remaining endpoints');
