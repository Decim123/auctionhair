document.addEventListener('DOMContentLoaded', () => {
    const hamburgerButton = document.getElementById('hamburger-button');
    const sidebar = document.getElementById('sidebar');
    const content = document.getElementById('content');
    const navLinks = document.querySelectorAll('.nav-link');

    hamburgerButton.addEventListener('click', () => {
        sidebar.classList.toggle('active');
        content.classList.toggle('shifted');
    });

    navLinks.forEach(link => {
        link.addEventListener('click', function(event) {
            event.preventDefault();
            const url = this.getAttribute('href');

            fetch(url, { credentials: 'include' })
                .then(response => {
                    if (!response.ok) {
                        throw new Error('Ошибка сети');
                    }
                    return response.text();
                })
                .then(html => {
                    content.innerHTML = html;
                    initializeStuffModal();
                    initializeVerifyModal();
                })
                .catch(error => {
                    console.error('Ошибка загрузки контента:', error);
                    content.innerHTML = '<p>Ошибка загрузки контента.</p>';
                });
        });
    });

    function initializeStuffModal() {
        const modal = document.getElementById("modal");
        const openModalBtn = document.getElementById("openModalBtn");
        const closeModalBtn = document.getElementById("closeModalBtn");
        const generateKeyBtn = document.getElementById("generateKeyBtn");
        const keyContainer = document.getElementById("keyContainer");
        const generatedKey = document.getElementById("generatedKey");
        const copyKeyBtn = document.getElementById("copyKeyBtn");

        if (!modal || !openModalBtn) return;

        openModalBtn.onclick = function() {
            modal.style.display = "block";
        }

        closeModalBtn.onclick = function() {
            modal.style.display = "none";
            keyContainer.style.display = "none";
            generatedKey.textContent = "";
        }

        window.onclick = function(event) {
            if (event.target == modal) {
                modal.style.display = "none";
                keyContainer.style.display = "none";
                generatedKey.textContent = "";
            }
        }

        generateKeyBtn.onclick = function() {
            const accessLevel = document.getElementById("accessLevel").value;
            fetch('/admin/key_gen', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ access_level: accessLevel })
            })
            .then(response => response.json())
            .then(data => {
                generatedKey.textContent = data.key;
                keyContainer.style.display = "block";
            })
            .catch(error => {
                console.error('Ошибка:', error);
            });
        }

        copyKeyBtn.onclick = function() {
            const key = generatedKey.textContent;
            navigator.clipboard.writeText(key).then(function() {
                alert('Ключ скопирован в буфер обмена');
            }, function(err) {
                console.error('Ошибка копирования:', err);
            });
        }
    }

    function initializeVerifyModal() {
        const modal = document.getElementById("verify-modal");
        const closeModalBtn = document.getElementById("closeVerifyModal");
        const openModalBtns = document.querySelectorAll(".openModalBtn");
        const acceptBtn = document.getElementById("acceptBtn");
        const rejectBtn = document.getElementById("rejectBtn");
        const resultMessage = document.getElementById("resultMessage");

        if (!modal || openModalBtns.length === 0) return;

        openModalBtns.forEach(btn => {
            btn.onclick = function() {
                const tg_id = this.getAttribute('data-tg_id');
                const name_1 = this.getAttribute('data-name_1');
                const name_2 = this.getAttribute('data-name_2');
                const name_3 = this.getAttribute('data-name_3');
                const date = this.getAttribute('data-date');

                document.getElementById('modalTgId').textContent = tg_id;
                document.getElementById('modalName1').textContent = name_1;
                document.getElementById('modalName2').textContent = name_2;
                document.getElementById('modalName3').textContent = name_3;
                document.getElementById('modalDate').textContent = date;

                document.getElementById('modalUserPic').src = `/static/img/userpic/verify/${tg_id}.png`;

                modal.style.display = "block";

                acceptBtn.onclick = function() {
                    fetch('/admin/verify_check', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({ tg_id: tg_id, status: 1 })
                    })
                    .then(response => response.json())
                    .then(data => {
                        resultMessage.textContent = 'Пользователь подтверждён.';
                    })
                    .catch(error => {
                        console.error('Ошибка:', error);
                    });
                };

                rejectBtn.onclick = function() {
                    fetch('/admin/verify_check', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({ tg_id: tg_id, status: 0 })
                    })
                    .then(response => response.json())
                    .then(data => {
                        resultMessage.textContent = 'Пользователь отклонён.';
                    })
                    .catch(error => {
                        console.error('Ошибка:', error);
                    });
                };
            };
        });

        closeModalBtn.onclick = function() {
            modal.style.display = "none";
            resultMessage.textContent = '';
        };

        window.onclick = function(event) {
            if (event.target == modal) {
                modal.style.display = "none";
                resultMessage.textContent = '';
            }
        };
    }
    // Инициализация модальных окон при загрузке страницы
    initializeStuffModal();
    initializeVerifyModal();
});
