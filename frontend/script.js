// Configuração da API
const API_BASE_URL = 'http://localhost:8080/api';

// Estado da aplicação
let currentEditId = null;
let livros = [];
let filteredLivros = [];

// Elementos DOM
const elements = {
    form: document.getElementById('livroForm'),
    formTitle: document.getElementById('formTitle'),
    submitBtnText: document.getElementById('submitBtnText'),
    cancelBtn: document.getElementById('cancelBtn'),
    livrosList: document.getElementById('livrosList'),
    loading: document.getElementById('loading'),
    emptyState: document.getElementById('emptyState'),
    searchInput: document.getElementById('searchInput'),
    searchBtn: document.getElementById('searchBtn'),
    clearSearchBtn: document.getElementById('clearSearchBtn'),
    filterDisponiveis: document.getElementById('filterDisponiveis'),
    totalLivros: document.getElementById('totalLivros'),
    livrosDisponiveis: document.getElementById('livrosDisponiveis'),
    confirmModal: document.getElementById('confirmModal'),
    confirmDelete: document.getElementById('confirmDelete'),
    cancelDelete: document.getElementById('cancelDelete'),
    toast: document.getElementById('toast')
};

// Inicialização
document.addEventListener('DOMContentLoaded', function() {
    initializeEventListeners();
    loadLivros();
    loadEstatisticas();
});

// Event Listeners
function initializeEventListeners() {
    elements.form.addEventListener('submit', handleFormSubmit);
    elements.cancelBtn.addEventListener('click', cancelEdit);
    elements.searchBtn.addEventListener('click', handleSearch);
    elements.clearSearchBtn.addEventListener('click', clearSearch);
    elements.filterDisponiveis.addEventListener('change', applyFilters);
    elements.searchInput.addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            handleSearch();
        }
    });
    
    // Modal events
    elements.cancelDelete.addEventListener('click', closeConfirmModal);
    elements.confirmModal.addEventListener('click', function(e) {
        if (e.target === elements.confirmModal) {
            closeConfirmModal();
        }
    });
}

// API Functions
async function apiRequest(endpoint, options = {}) {
    const url = `${API_BASE_URL}${endpoint}`;
    const config = {
        headers: {
            'Content-Type': 'application/json',
            ...options.headers
        },
        ...options
    };
    
    try {
        const response = await fetch(url, config);
        
        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            throw new Error(errorData.erro || `HTTP error! status: ${response.status}`);
        }
        
        return await response.json();
    } catch (error) {
        console.error('API Error:', error);
        throw error;
    }
}

async function loadLivros() {
    showLoading(true);
    try {
        livros = await apiRequest('/livros');
        filteredLivros = [...livros];
        renderLivros();
        updateEstatisticas();
    } catch (error) {
        showToast('Erro ao carregar livros: ' + error.message, 'error');
    } finally {
        showLoading(false);
    }
}

async function loadEstatisticas() {
    try {
        const stats = await apiRequest('/livros/estatisticas');
        elements.totalLivros.textContent = stats.total;
        elements.livrosDisponiveis.textContent = stats.disponiveis;
    } catch (error) {
        console.error('Erro ao carregar estatísticas:', error);
    }
}

async function saveLivro(livroData) {
    const endpoint = currentEditId ? `/livros/${currentEditId}` : '/livros';
    const method = currentEditId ? 'PUT' : 'POST';
    
    try {
        await apiRequest(endpoint, {
            method: method,
            body: JSON.stringify(livroData)
        });
        
        showToast(
            currentEditId ? 'Livro atualizado com sucesso!' : 'Livro adicionado com sucesso!',
            'success'
        );
        
        resetForm();
        loadLivros();
        loadEstatisticas();
    } catch (error) {
        showToast('Erro ao salvar livro: ' + error.message, 'error');
    }
}

async function deleteLivro(id) {
    try {
        await apiRequest(`/livros/${id}`, { method: 'DELETE' });
        showToast('Livro excluído com sucesso!', 'success');
        loadLivros();
        loadEstatisticas();
    } catch (error) {
        showToast('Erro ao excluir livro: ' + error.message, 'error');
    }
}

// Form Functions
function handleFormSubmit(e) {
    e.preventDefault();
    
    const formData = new FormData(elements.form);
    const livroData = {
        titulo: formData.get('titulo').trim(),
        autor: formData.get('autor').trim(),
        isbn: formData.get('isbn').trim(),
        anoPublicacao: parseInt(formData.get('anoPublicacao')),
        editora: formData.get('editora').trim() || null,
        descricao: formData.get('descricao').trim() || null,
        disponivel: formData.get('disponivel') === 'true'
    };
    
    // Validação básica
    if (!livroData.titulo || !livroData.autor || !livroData.isbn || !livroData.anoPublicacao) {
        showToast('Por favor, preencha todos os campos obrigatórios.', 'warning');
        return;
    }
    
    if (livroData.anoPublicacao < 1000 || livroData.anoPublicacao > 2030) {
        showToast('Ano de publicação deve estar entre 1000 e 2030.', 'warning');
        return;
    }
    
    saveLivro(livroData);
}

function editLivro(livro) {
    currentEditId = livro.id;
    
    // Preencher formulário
    document.getElementById('titulo').value = livro.titulo;
    document.getElementById('autor').value = livro.autor;
    document.getElementById('isbn').value = livro.isbn;
    document.getElementById('anoPublicacao').value = livro.anoPublicacao;
    document.getElementById('editora').value = livro.editora || '';
    document.getElementById('descricao').value = livro.descricao || '';
    document.getElementById('disponivel').value = livro.disponivel.toString();
    
    // Atualizar UI
    elements.formTitle.textContent = 'Editar Livro';
    elements.submitBtnText.textContent = 'Atualizar';
    elements.cancelBtn.style.display = 'inline-flex';
    
    // Scroll para o formulário
    document.querySelector('.form-section').scrollIntoView({ behavior: 'smooth' });
}

function cancelEdit() {
    resetForm();
}

function resetForm() {
    currentEditId = null;
    elements.form.reset();
    elements.formTitle.textContent = 'Adicionar Novo Livro';
    elements.submitBtnText.textContent = 'Salvar';
    elements.cancelBtn.style.display = 'none';
}

// Search and Filter Functions
function handleSearch() {
    const searchTerm = elements.searchInput.value.trim();
    if (searchTerm) {
        searchLivros(searchTerm);
    } else {
        applyFilters();
    }
}

async function searchLivros(termo) {
    showLoading(true);
    try {
        const results = await apiRequest(`/livros/buscar?termo=${encodeURIComponent(termo)}`);
        filteredLivros = results;
        renderLivros();
    } catch (error) {
        showToast('Erro na busca: ' + error.message, 'error');
    } finally {
        showLoading(false);
    }
}

function clearSearch() {
    elements.searchInput.value = '';
    elements.filterDisponiveis.checked = false;
    filteredLivros = [...livros];
    renderLivros();
}

function applyFilters() {
    const searchTerm = elements.searchInput.value.trim().toLowerCase();
    const onlyAvailable = elements.filterDisponiveis.checked;
    
    filteredLivros = livros.filter(livro => {
        const matchesSearch = !searchTerm || 
            livro.titulo.toLowerCase().includes(searchTerm) ||
            livro.autor.toLowerCase().includes(searchTerm) ||
            (livro.editora && livro.editora.toLowerCase().includes(searchTerm));
        
        const matchesAvailability = !onlyAvailable || livro.disponivel;
        
        return matchesSearch && matchesAvailability;
    });
    
    renderLivros();
}

// Render Functions
function renderLivros() {
    if (filteredLivros.length === 0) {
        elements.livrosList.style.display = 'none';
        elements.emptyState.style.display = 'block';
        return;
    }
    
    elements.livrosList.style.display = 'block';
    elements.emptyState.style.display = 'none';
    
    elements.livrosList.innerHTML = filteredLivros.map(livro => `
        <div class="livro-card">
            <div class="livro-header">
                <div>
                    <div class="livro-title">${escapeHtml(livro.titulo)}</div>
                    <div class="livro-author">por ${escapeHtml(livro.autor)}</div>
                </div>
                <span class="livro-status ${livro.disponivel ? 'status-disponivel' : 'status-indisponivel'}">
                    ${livro.disponivel ? 'Disponível' : 'Indisponível'}
                </span>
            </div>
            
            <div class="livro-details">
                <div class="livro-detail">
                    <span class="detail-label">ISBN</span>
                    <span class="detail-value">${escapeHtml(livro.isbn)}</span>
                </div>
                <div class="livro-detail">
                    <span class="detail-label">Ano</span>
                    <span class="detail-value">${livro.anoPublicacao}</span>
                </div>
                ${livro.editora ? `
                <div class="livro-detail">
                    <span class="detail-label">Editora</span>
                    <span class="detail-value">${escapeHtml(livro.editora)}</span>
                </div>
                ` : ''}
            </div>
            
            ${livro.descricao ? `
            <div class="livro-description">
                ${escapeHtml(livro.descricao)}
            </div>
            ` : ''}
            
            <div class="livro-actions">
                <button class="btn btn-warning btn-small" onclick="editLivro(${JSON.stringify(livro).replace(/"/g, '&quot;')})">
                    <i class="fas fa-edit"></i> Editar
                </button>
                <button class="btn btn-danger btn-small" onclick="confirmDeleteLivro(${livro.id})">
                    <i class="fas fa-trash"></i> Excluir
                </button>
            </div>
        </div>
    `).join('');
}

function updateEstatisticas() {
    const total = livros.length;
    const disponiveis = livros.filter(livro => livro.disponivel).length;
    
    elements.totalLivros.textContent = total;
    elements.livrosDisponiveis.textContent = disponiveis;
}

// Delete Confirmation
let deleteId = null;

function confirmDeleteLivro(id) {
    deleteId = id;
    elements.confirmModal.style.display = 'block';
}

function closeConfirmModal() {
    deleteId = null;
    elements.confirmModal.style.display = 'none';
}

elements.confirmDelete.addEventListener('click', function() {
    if (deleteId) {
        deleteLivro(deleteId);
        closeConfirmModal();
    }
});

// Utility Functions
function showLoading(show) {
    elements.loading.style.display = show ? 'block' : 'none';
}

function showToast(message, type = 'success') {
    elements.toast.textContent = message;
    elements.toast.className = `toast ${type}`;
    elements.toast.classList.add('show');
    
    setTimeout(() => {
        elements.toast.classList.remove('show');
    }, 3000);
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Error handling for global errors
window.addEventListener('error', function(e) {
    console.error('Global error:', e.error);
    showToast('Ocorreu um erro inesperado. Verifique o console para mais detalhes.', 'error');
});

// Handle API connection errors
window.addEventListener('unhandledrejection', function(e) {
    console.error('Unhandled promise rejection:', e.reason);
    if (e.reason.message && e.reason.message.includes('fetch')) {
        showToast('Erro de conexão com o servidor. Verifique se o backend está rodando.', 'error');
    }
});

