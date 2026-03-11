/**
 * grades.js
 * Lógica de gestión de calificaciones
 */

/** Devuelve el estado de una nota (aprobado/reprobado) */
function getGradeStatus(nota) {
  const n = parseFloat(nota);
  if (n >= 10) return { label: 'Aprobado', css: 'badge-success' };
  if (n >= 9) return { label: 'Reparación', css: 'badge-warning' };
  return { label: 'Reprobado', css: 'badge-danger' };
}

/** Renderiza la tabla de calificaciones */
function renderGrades(grades) {
  const tbody = document.getElementById('grades-body');
  if (!grades || grades.length === 0) {
    tbody.innerHTML = '<tr><td colspan="7" class="empty-row">No hay calificaciones registradas</td></tr>';
    return;
  }
  const students = Storage.getAll(STORAGE_KEYS.STUDENTS);
  const courses = Storage.getAll(STORAGE_KEYS.COURSES);

  tbody.innerHTML = grades.map(g => {
    const student = students.find(s => s.id === g.studentId);
    const course = courses.find(c => c.id === g.courseId);
    const status = getGradeStatus(g.nota);
    return `
      <tr>
        <td>${student ? escapeHtml(`${student.nombre} ${student.apellido}`) : '—'}</td>
        <td>${student ? escapeHtml(student.cedula) : '—'}</td>
        <td>${course ? escapeHtml(course.nombre) : '—'}</td>
        <td><strong>${parseFloat(g.nota).toFixed(1)}</strong></td>
        <td>${escapeHtml(g.periodo)}</td>
        <td><span class="badge ${status.css}">${status.label}</span></td>
        <td>
          <div class="action-btns">
            <button class="btn-icon" title="Editar" onclick="editGrade('${escapeHtml(g.id)}')">✏️</button>
            <button class="btn-icon" title="Eliminar" onclick="confirmDeleteGrade('${escapeHtml(g.id)}')">🗑️</button>
          </div>
        </td>
      </tr>
    `;
  }).join('');
}

/** Carga y renderiza todas las calificaciones */
function loadGrades() {
  const grades = Storage.getAll(STORAGE_KEYS.GRADES);
  renderGrades(grades);
}

/** Filtra calificaciones por búsqueda */
function filterGrades() {
  const query = document.getElementById('grade-search').value.toLowerCase();
  const students = Storage.getAll(STORAGE_KEYS.STUDENTS);
  const courses = Storage.getAll(STORAGE_KEYS.COURSES);
  const grades = Storage.getAll(STORAGE_KEYS.GRADES).filter(g => {
    const student = students.find(s => s.id === g.studentId);
    const course = courses.find(c => c.id === g.courseId);
    const studentName = student ? `${student.nombre} ${student.apellido}`.toLowerCase() : '';
    const courseName = course ? course.nombre.toLowerCase() : '';
    return studentName.includes(query) || courseName.includes(query);
  });
  renderGrades(grades);
}

/** Rellena los selects de estudiante y materia en el modal de calificación */
function populateGradeSelects() {
  const studentSelect = document.getElementById('grade-student');
  const courseSelect = document.getElementById('grade-course');

  const students = Storage.getAll(STORAGE_KEYS.STUDENTS);
  const courses = Storage.getAll(STORAGE_KEYS.COURSES);

  const currentStudentVal = studentSelect.value;
  const currentCourseVal = courseSelect.value;

  studentSelect.innerHTML = '<option value="">Seleccione estudiante...</option>' +
    students.map(s => `<option value="${s.id}">${escapeHtml(s.cedula)} - ${escapeHtml(s.nombre)} ${escapeHtml(s.apellido)}</option>`).join('');

  courseSelect.innerHTML = '<option value="">Seleccione materia...</option>' +
    courses.map(c => `<option value="${c.id}">${escapeHtml(c.codigo)} - ${escapeHtml(c.nombre)}</option>`).join('');

  // Restaurar selección si existía
  if (currentStudentVal) studentSelect.value = currentStudentVal;
  if (currentCourseVal) courseSelect.value = currentCourseVal;
}

/** Abre el formulario para editar una calificación */
function editGrade(id) {
  const g = Storage.findById(STORAGE_KEYS.GRADES, id);
  if (!g) return;
  populateGradeSelects();
  document.getElementById('grade-id').value = g.id;
  document.getElementById('grade-student').value = g.studentId;
  document.getElementById('grade-course').value = g.courseId;
  document.getElementById('grade-nota').value = g.nota;
  document.getElementById('grade-periodo').value = g.periodo;
  document.getElementById('grade-tipo').value = g.tipo || 'Final';
  document.getElementById('grade-modal-title').textContent = 'Editar Calificación';
  openModal('grade-modal');
}

/** Confirma eliminación de calificación */
function confirmDeleteGrade(id) {
  document.getElementById('confirm-message').textContent = '¿Está seguro que desea eliminar esta calificación?';
  document.getElementById('confirm-delete-btn').onclick = () => deleteGrade(id);
  openModal('confirm-modal');
}

/** Elimina una calificación */
function deleteGrade(id) {
  Storage.remove(STORAGE_KEYS.GRADES, id);
  closeModal('confirm-modal');
  loadGrades();
  updateDashboard();
  showToast('Calificación eliminada correctamente', 'success');
}

/** Guarda (crea o actualiza) una calificación */
function saveGrade(event) {
  event.preventDefault();
  clearGradeErrors();

  const id = document.getElementById('grade-id').value;
  const studentId = document.getElementById('grade-student').value;
  const courseId = document.getElementById('grade-course').value;
  const nota = document.getElementById('grade-nota').value;
  const periodo = document.getElementById('grade-periodo').value.trim();
  const tipo = document.getElementById('grade-tipo').value;

  let valid = true;

  if (!studentId) {
    showFieldError('err-grade-student', 'Seleccione un estudiante');
    document.getElementById('grade-student').classList.add('error');
    valid = false;
  }
  if (!courseId) {
    showFieldError('err-grade-course', 'Seleccione una materia');
    document.getElementById('grade-course').classList.add('error');
    valid = false;
  }
  if (nota === '' || parseFloat(nota) < 0 || parseFloat(nota) > 20) {
    showFieldError('err-grade-nota', 'La nota debe estar entre 0 y 20');
    document.getElementById('grade-nota').classList.add('error');
    valid = false;
  }
  if (!periodo) {
    showFieldError('err-grade-periodo', 'El período es requerido');
    document.getElementById('grade-periodo').classList.add('error');
    valid = false;
  }

  if (!valid) return;

  const gradeData = { studentId, courseId, nota: parseFloat(nota), periodo, tipo };

  if (id) {
    Storage.update(STORAGE_KEYS.GRADES, id, gradeData);
    showToast('Calificación actualizada correctamente', 'success');
  } else {
    Storage.add(STORAGE_KEYS.GRADES, gradeData);
    showToast('Calificación registrada correctamente', 'success');
  }

  closeModal('grade-modal');
  loadGrades();
  updateDashboard();
  renderReports();
}

function clearGradeErrors() {
  ['grade-student', 'grade-course', 'grade-nota', 'grade-periodo'].forEach(id => {
    document.getElementById(id).classList.remove('error');
  });
  ['err-grade-student', 'err-grade-course', 'err-grade-nota', 'err-grade-periodo'].forEach(id => {
    document.getElementById(id).textContent = '';
  });
}
