<template>
  <main class="main-area-content">
    <div class="content-header-area">
      <slot name="content-header" />
    </div>

    <div class="main-content">
      <slot />
    </div>
  </main>
</template>

<style scoped>
.main-area-content {
  height: 100%;
  flex: 1;
  display: flex;
  flex-direction: column;
  padding: var(--space-6) 0 0;
  max-width: 100vw;
}

.content-header-area {
  width: 100%;
  padding: 0 var(--space-6) var(--space-6);
}

.main-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 var(--space-6) var(--space-6);
  width: 100%;
  flex: 1;
}

@media (--tablet-viewport) {
  .main-area-content {
    padding-top: var(--space-4);
  }

  .content-header-area {
    padding: 0 var(--space-4) var(--space-4);
  }

  .main-content {
    padding: 0 var(--space-3) var(--space-3);
  }
}
</style>
