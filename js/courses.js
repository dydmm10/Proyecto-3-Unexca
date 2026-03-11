/**
 * courses.js
 * Lógica de gestión de materias
 */

/** Renderiza la tabla de materias */
function renderCourses(courses) {
  const tbody = document.getElementById('courses-body');
  if (!courses || courses.length === 0) {
    tbody.innerHTML = '<tr><td colspan="6" class="empty-row">No hay materias registradas</td></tr>';
    return;
  }
  tbody.innerHTML = courses.map(c => `
    <tr>
      <td><strong>${escapeHtml(c.codigo)}</strong></td>
      <td>${escapeHtml(c.nombre)}</td>
      <td>${escapeHtml(c.semestre)}° Sem.</td>
      <td>${escapeHtml(c.creditos)} UC</td>
      <td>${escapeHtml(c.profesor || '—')}</td>
      <td>
        <div class="action-btns">
          <button class="btn-icon" title="Editar" onclick="editCourse('${escapeHtml(c.id)}')">✏️</button>
          <button class="btn-icon" title="Eliminar" onclick="confirmDeleteCourse('${escapeHtml(c.id)}')">🗑️</button>
        </div>
      </td>
    </tr>
  `).join('');
}

/** Carga y renderiza todas las materias */
function loadCourses() {
  const courses = Storage.getAll(STORAGE_KEYS.COURSES);
  renderCourses(courses);
}

/** Filtra materias por búsqueda */
function filterCourses() {
  const query = document.getElementById('course-search').value.toLowerCase();
  const courses = Storage.getAll(STORAGE_KEYS.COURSES).filter(c =>
    c.codigo.toLowerCase().includes(query) ||
    c.nombre.toLowerCase().includes(query) ||
    (c.profesor && c.profesor.toLowerCase().includes(query))
  );
  renderCourses(courses);
}

/** Abre el formulario para editar una materia */
function editCourse(id) {
  const c = Storage.findById(STORAGE_KEYS.COURSES, id);
  if (!c) return;
  document.getElementById('course-id').value = c.id;
  document.getElementById('course-codigo').value = c.codigo;
  document.getElementById('course-nombre').value = c.nombre;
  document.getElementById('course-semestre').value = c.semestre;
  document.getElementById('course-creditos').value = c.creditos;
  document.getElementById('course-profesor').value = c.profesor || '';
  document.getElementById('course-horario').value = c.horario || '';
  document.getElementById('course-descripcion').value = c.descripcion || '';
  document.getElementById('course-modal-title').textContent = 'Editar Materia';
  openModal('course-modal');
}

/** Confirma eliminación de materia */
function confirmDeleteCourse(id) {
  const c = Storage.findById(STORAGE_KEYS.COURSES, id);
  if (!c) return;
  document.getElementById('confirm-message').textContent =
    `¿Está seguro que desea eliminar la materia "${c.nombre}"?`;
  document.getElementById('confirm-delete-btn').onclick = () => deleteCourse(id);
  openModal('confirm-modal');
}

/** Elimina una materia */
function deleteCourse(id) {
  Storage.remove(STORAGE_KEYS.COURSES, id);
  closeModal('confirm-modal');
  loadCourses();
  updateDashboard();
  showToast('Materia eliminada correctamente', 'success');
}

/** Guarda (crea o actualiza) una materia */
function saveCourse(event) {
  event.preventDefault();
  clearCourseErrors();

  const id = document.getElementById('course-id').value;
  const codigo = document.getElementById('course-codigo').value.trim();
  const nombre = document.getElementById('course-nombre').value.trim();
  const semestre = document.getElementById('course-semestre').value;
  const creditos = document.getElementById('course-creditos').value;
  const profesor = document.getElementById('course-profesor').value.trim();
  const horario = document.getElementById('course-horario').value.trim();
  const descripcion = document.getElementById('course-descripcion').value.trim();

  let valid = true;

  if (!codigo) {
    showFieldError('err-course-codigo', 'El código es requerido');
    document.getElementById('course-codigo').classList.add('error');
    valid = false;
  }
  if (!nombre) {
    showFieldError('err-course-nombre', 'El nombre es requerido');
    document.getElementById('course-nombre').classList.add('error');
    valid = false;
  }
  if (!semestre) {
    showFieldError('err-course-semestre', 'El semestre es requerido');
    document.getElementById('course-semestre').classList.add('error');
    valid = false;
  }
  if (!creditos || creditos < 1 || creditos > 10) {
    showFieldError('err-course-creditos', 'Las unidades de crédito deben estar entre 1 y 10');
    document.getElementById('course-creditos').classList.add('error');
    valid = false;
  }

  if (!valid) return;

  // Verificar código duplicado (excepto al editar el mismo registro)
  const existing = Storage.getAll(STORAGE_KEYS.COURSES).find(
    c => c.codigo.toLowerCase() === codigo.toLowerCase() && c.id !== id
  );
  if (existing) {
    showFieldError('err-course-codigo', 'Ya existe una materia con este código');
    document.getElementById('course-codigo').classList.add('error');
    return;
  }

  const courseData = { codigo, nombre, semestre, creditos, profesor, horario, descripcion };

  if (id) {
    Storage.update(STORAGE_KEYS.COURSES, id, courseData);
    showToast('Materia actualizada correctamente', 'success');
  } else {
    Storage.add(STORAGE_KEYS.COURSES, courseData);
    showToast('Materia registrada correctamente', 'success');
  }

  closeModal('course-modal');
  loadCourses();
  updateDashboard();
}

function clearCourseErrors() {
  ['course-codigo', 'course-nombre', 'course-semestre', 'course-creditos'].forEach(id => {
    document.getElementById(id).classList.remove('error');
  });
  ['err-course-codigo', 'err-course-nombre', 'err-course-semestre', 'err-course-creditos'].forEach(id => {
    document.getElementById(id).textContent = '';
  });
}
