/**
 * app.js
 * Punto de entrada y utilidades globales
 */

// ─── Navegación entre secciones ─────────────────────────────────────────────

function showSection(name) {
  document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
  document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));

  const section = document.getElementById(`section-${name}`);
  if (section) section.classList.add('active');

  const btn = document.querySelector(`.nav-btn[data-section="${name}"]`);
  if (btn) btn.classList.add('active');

  if (name === 'reports') renderReports();
}

// ─── Modales ─────────────────────────────────────────────────────────────────

function openModal(id) {
  const modal = document.getElementById(id);
  if (!modal) return;

  // Limpiar el formulario antes de abrir (excepto en edición)
  if (id === 'student-modal') {
    const isEdit = Boolean(document.getElementById('student-id').value);
    if (!isEdit) resetStudentForm();
  } else if (id === 'course-modal') {
    const isEdit = Boolean(document.getElementById('course-id').value);
    if (!isEdit) resetCourseForm();
  } else if (id === 'grade-modal') {
    const isEdit = Boolean(document.getElementById('grade-id').value);
    if (!isEdit) resetGradeForm();
    populateGradeSelects();
  }

  modal.classList.add('open');
}

function closeModal(id) {
  const modal = document.getElementById(id);
  if (modal) modal.classList.remove('open');
}

function resetStudentForm() {
  document.getElementById('student-id').value = '';
  document.getElementById('student-form').reset();
  document.getElementById('student-modal-title').textContent = 'Registrar Estudiante';
  clearStudentErrors();
}

function resetCourseForm() {
  document.getElementById('course-id').value = '';
  document.getElementById('course-form').reset();
  document.getElementById('course-modal-title').textContent = 'Registrar Materia';
  clearCourseErrors();
}

function resetGradeForm() {
  document.getElementById('grade-id').value = '';
  document.getElementById('grade-form').reset();
  document.getElementById('grade-modal-title').textContent = 'Registrar Calificación';
  clearGradeErrors();
}

// Cerrar modal al hacer clic fuera del contenido
document.addEventListener('click', function (e) {
  if (e.target.classList.contains('modal') && e.target.classList.contains('open')) {
    e.target.classList.remove('open');
  }
});

// Cerrar modal con Escape
document.addEventListener('keydown', function (e) {
  if (e.key === 'Escape') {
    document.querySelectorAll('.modal.open').forEach(m => m.classList.remove('open'));
  }
});

// ─── Dashboard ───────────────────────────────────────────────────────────────

function updateDashboard() {
  const students = Storage.getAll(STORAGE_KEYS.STUDENTS);
  const courses = Storage.getAll(STORAGE_KEYS.COURSES);
  const grades = Storage.getAll(STORAGE_KEYS.GRADES);

  document.getElementById('stat-students').textContent = students.length;
  document.getElementById('stat-courses').textContent = courses.length;
  document.getElementById('stat-grades').textContent = grades.length;

  if (grades.length > 0) {
    const avg = grades.reduce((sum, g) => sum + parseFloat(g.nota), 0) / grades.length;
    document.getElementById('stat-avg').textContent = avg.toFixed(1);
  } else {
    document.getElementById('stat-avg').textContent = '—';
  }

  // Últimos 5 estudiantes registrados
  const recentStudentsBody = document.getElementById('recent-students-body');
  const recent = [...students].reverse().slice(0, 5);
  if (recent.length === 0) {
    recentStudentsBody.innerHTML = '<tr><td colspan="4" class="empty-row">Sin registros</td></tr>';
  } else {
    recentStudentsBody.innerHTML = recent.map(s => `
      <tr>
        <td>${escapeHtml(s.cedula)}</td>
        <td>${escapeHtml(s.nombre)} ${escapeHtml(s.apellido)}</td>
        <td>${escapeHtml(s.semestre)}° Sem.</td>
        <td>${escapeHtml(s.carrera)}</td>
      </tr>
    `).join('');
  }

  // Últimas 5 calificaciones
  const recentGradesBody = document.getElementById('recent-grades-body');
  const recentGrades = [...grades].reverse().slice(0, 5);
  if (recentGrades.length === 0) {
    recentGradesBody.innerHTML = '<tr><td colspan="4" class="empty-row">Sin registros</td></tr>';
  } else {
    recentGradesBody.innerHTML = recentGrades.map(g => {
      const student = students.find(s => s.id === g.studentId);
      const course = courses.find(c => c.id === g.courseId);
      const status = getGradeStatus(g.nota);
      return `
        <tr>
          <td>${student ? escapeHtml(`${student.nombre} ${student.apellido}`) : '—'}</td>
          <td>${course ? escapeHtml(course.nombre) : '—'}</td>
          <td><strong>${parseFloat(g.nota).toFixed(1)}</strong></td>
          <td><span class="badge ${status.css}">${status.label}</span></td>
        </tr>
      `;
    }).join('');
  }
}

// ─── Toast Notifications ─────────────────────────────────────────────────────

let toastTimer = null;

function showToast(message, type = 'success') {
  const toast = document.getElementById('toast');
  toast.textContent = message;
  toast.className = `toast show ${type}`;
  if (toastTimer) clearTimeout(toastTimer);
  toastTimer = setTimeout(() => {
    toast.classList.remove('show');
  }, 3000);
}

// ─── Utilidades ──────────────────────────────────────────────────────────────

function escapeHtml(str) {
  if (str === null || str === undefined) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

function showFieldError(id, message) {
  const el = document.getElementById(id);
  if (el) el.textContent = message;
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

// ─── Inicialización ───────────────────────────────────────────────────────────

document.addEventListener('DOMContentLoaded', function () {
  loadStudents();
  loadCourses();
  loadGrades();
  updateDashboard();
});
