const fs = require('fs');
const collection = JSON.parse(fs.readFileSync('postman_collection.json', 'utf8'));

// Professor (JWT) endpoints
const professorJWT = {
  name: 'Professor (JWT)',
  item: [
    {
      name: 'Get Schedule',
      request: {
        method: 'GET',
        header: [{ key: 'Authorization', value: 'Bearer {{jwt_token}}' }],
        url: { raw: '{{base_url}}/professor/schedule', host: ['{{base_url}}'], path: ['professor', 'schedule'] }
      }
    },
    {
      name: 'Create Schedule',
      request: {
        method: 'POST',
        header: [
          { key: 'Authorization', value: 'Bearer {{jwt_token}}' },
          { key: 'Content-Type', value: 'application/json' }
        ],
        body: {
          mode: 'raw',
          raw: JSON.stringify({ date: '2024-01-15', startTime: '2024-01-15T10:00:00Z', endTime: '2024-01-15T11:00:00Z', isAvailable: true }, null, 2)
        },
        url: { raw: '{{base_url}}/professor/schedule', host: ['{{base_url}}'], path: ['professor', 'schedule'] }
      }
    },
    {
      name: 'Update Schedule',
      request: {
        method: 'PUT',
        header: [
          { key: 'Authorization', value: 'Bearer {{jwt_token}}' },
          { key: 'Content-Type', value: 'application/json' }
        ],
        body: {
          mode: 'raw',
          raw: JSON.stringify({ isAvailable: false }, null, 2)
        },
        url: { raw: '{{base_url}}/professor/schedule/{{schedule_id}}', host: ['{{base_url}}'], path: ['professor', 'schedule', '{{schedule_id}}'] }
      }
    },
    {
      name: 'Delete Schedule',
      request: {
        method: 'DELETE',
        header: [{ key: 'Authorization', value: 'Bearer {{jwt_token}}' }],
        url: { raw: '{{base_url}}/professor/schedule/{{schedule_id}}', host: ['{{base_url}}'], path: ['professor', 'schedule', '{{schedule_id}}'] }
      }
    },
    {
      name: 'Get Income Report',
      request: {
        method: 'GET',
        header: [{ key: 'Authorization', value: 'Bearer {{jwt_token}}' }],
        url: { raw: '{{base_url}}/professor/income-report', host: ['{{base_url}}'], path: ['professor', 'income-report'] }
      }
    },
    {
      name: 'Get Students',
      request: {
        method: 'GET',
        header: [{ key: 'Authorization', value: 'Bearer {{jwt_token}}' }],
        url: { raw: '{{base_url}}/professor/students', host: ['{{base_url}}'], path: ['professor', 'students'] }
      }
    },
    {
      name: 'Create Service',
      request: {
        method: 'POST',
        header: [
          { key: 'Authorization', value: 'Bearer {{jwt_token}}' },
          { key: 'Content-Type', value: 'application/json' }
        ],
        body: {
          mode: 'raw',
          raw: JSON.stringify({ name: 'Clase Individual', description: 'Clase personalizada', price: 50000, duration: 60 }, null, 2)
        },
        url: { raw: '{{base_url}}/professor/services', host: ['{{base_url}}'], path: ['professor', 'services'] }
      }
    },
    {
      name: 'Update Service',
      request: {
        method: 'PUT',
        header: [
          { key: 'Authorization', value: 'Bearer {{jwt_token}}' },
          { key: 'Content-Type', value: 'application/json' }
        ],
        body: {
          mode: 'raw',
          raw: JSON.stringify({ name: 'Clase Individual Actualizada', price: 55000 }, null, 2)
        },
        url: { raw: '{{base_url}}/professor/services/{{service_id}}', host: ['{{base_url}}'], path: ['professor', 'services', '{{service_id}}'] }
      }
    },
    {
      name: 'Get Services',
      request: {
        method: 'GET',
        header: [{ key: 'Authorization', value: 'Bearer {{jwt_token}}' }],
        url: { raw: '{{base_url}}/professor/services', host: ['{{base_url}}'], path: ['professor', 'services'] }
      }
    },
    {
      name: 'Delete Service',
      request: {
        method: 'DELETE',
        header: [{ key: 'Authorization', value: 'Bearer {{jwt_token}}' }],
        url: { raw: '{{base_url}}/professor/services/{{service_id}}', host: ['{{base_url}}'], path: ['professor', 'services', '{{service_id}}'] }
      }
    },
    {
      name: 'Create Payment',
      request: {
        method: 'POST',
        header: [
          { key: 'Authorization', value: 'Bearer {{jwt_token}}' },
          { key: 'Content-Type', value: 'application/json' }
        ],
        body: {
          mode: 'raw',
          raw: JSON.stringify({ studentId: '{{student_id}}', amount: 50000, date: '2024-01-15', notes: 'Pago de clase' }, null, 2)
        },
        url: { raw: '{{base_url}}/professor/payments', host: ['{{base_url}}'], path: ['professor', 'payments'] }
      }
    }
  ]
};

collection.item.push(professorJWT);
fs.writeFileSync('postman_collection.json', JSON.stringify(collection, null, 2));
console.log('Added Professor (JWT) endpoints');
